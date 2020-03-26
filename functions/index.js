// File to manage all Cloud Functions
// Only use Cloud Firestore! Not Realtime database, and watch out for the different methods required


// Dependancies
const functions = require('firebase-functions');
const admin = require('firebase-admin');
// const gcs = require('@google-cloud/storage');
const mangopay = require('mangopay2-nodejs-sdk');
const helpers = require('./helpers.js')

const mpAPI = new mangopay({
                       clientId: 'wildfirewallet',
                       clientApiKey: 'cwSQuWi9RCbnr5Fh5HktxevT9ch0pK3wWUn4t5rHJkCP1KSCiu'
                       // Set the right production API url. If testing, omit the property since it defaults to sandbox URL
                       // baseUrl: 'https://api.mangopay.com'
                       });

admin.initializeApp(functions.config().firebase);

// // Cloud Functions Reference
// // https://firebase.google.com/docs/functions/write-firebase-functions

// Each function requires its own exports.customFunction

exports.addTransactionsToUsers = functions.region('europe-west1').firestore
  .document('transactions/{transactionID}')
  .onCreate( async (snap, context) => {
  const db = admin.firestore()

  const transactionID = context.params.transactionID
  
  // Get an object representing the document
  const data = snap.data();

  // get the payer and recipient user IDs
  const payerID = data.from;
  const recipientID = data.to;

  // get a ref to the payer and recipient user docs
  let payerDocRef = db.collection('users').doc(payerID);
  let recipientDocRef = db.collection('users').doc(recipientID);

  var payerName = ""
  var recipientName = ""

  // get the payer name 
  await payerDocRef.get().then(doc => {
    return payerName = doc.data().fullname
  })
  .catch(err => {
    balanceFail = true
    console.log('Error getting payer name', err);
  });

  // get the recipient name
  await recipientDocRef.get().then(doc => {
    return recipientName = doc.data().fullname
  })
  .catch(err => {
    balanceFail = true
    console.log('Error getting recipient name', err);
  });

  // pull the transaction Data to be added to the payer transaction subcollection
  const payerTransactionData = {
    payerID: data.from,
    payerName: payerName,
    recipientID: data.to,
    recipientName: recipientName,
    datetime: data.datetime,
    currency: data.currency,
    amount: data.amount,

    userIsPayer: true
  };

  // pull the transaction Data to be added to the recipient transaction subcollection
  const recipientTransactionData = {
    payerID: data.from,
    payerName: payerName,
    recipientID: data.to,
    recipientName: recipientName,
    datetime: data.datetime,
    currency: data.currency,
    amount: data.amount,

    userIsPayer: false
  };

  // within the 'receipts' subcollection for the payer and recipient user docs, we add a doc with the transactionID
  return payerDocRef.collection('receipts').doc(transactionID).set(payerTransactionData), recipientDocRef.collection('receipts').doc(transactionID).set(recipientTransactionData)
});

// When a user is created, register them with MangoPay and add an empty PaymentMethods collection
exports.createNewMangopayCustomer = functions.region('europe-west1').firestore.document('users/{id}').onCreate(async (snap, context) => {

  // TODO if this func fails for whatever reason, it should be retried (data is already in Firestore database)
  
  const data = snap.data()

  const userID = context.params.id

  var firstname = data.firstname
  var lastname = data.lastname
  var email = data.email
  var birthday = data.dob
  var nationality = data.nationality
  var residence = data.residence
  // const currencyType = data.currency

  var mangopayIDArray = []
  var walletName = "GBP Wallet"

  const customer = await mpAPI.Users.create({PersonType: 'NATURAL', FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email})

  const mangopayID = customer.Id
  mangopayIDArray.push(mangopayID)

  const wallet = await mpAPI.Wallets.create({Owners: mangopayIDArray, Description: walletName, Currency: "GBP"})

  const walletID = wallet.Id

  if (mangopayID !== "" && walletID !== "") {
    // we need to add a Wallet to the user's Firestore record - this will store the card token(s) for repeat payments

    admin.firestore().collection('users').doc(userID).set({
      mangopayID: mangopayID,
      defaultWalletID: walletID
    }, {merge: true})
    // DO NOT DELETE 'merge: true' unless you're really sure
    .catch(err => {
      console.log(`${userID}: Error saving mangopayID and walletID to database`, err);
    })

    admin.firestore().collection('users').doc(userID).collection('wallets').doc(walletID).set({
      created: wallet.CreationDate,
      balance: wallet.Balance['Amount'],
      description: wallet.Description,
      currency: wallet.Currency,
      // I'm not sure this line is needed
      // temp_card_registration_id: cardReg.Id
    })
    .catch(err => {
      console.log(`${userID}: Error saving wallet to user wallet database`, err);
    })
    return 
  } else {
    console.log(`${userID}: creating a user and wallet in mangopay failed`, err)
    admin.firestore().collection('userCreationFailed').doc(userID).set({
      firstname: data.firstname,
      lastname: data.lastname,
      email: data.email,
      birthday: data.dob,
      nationality: data.nationality,
      residence: data.residence,
      // const currencyType = data.currency

      mangopayID: mangopayID,
      walletID: walletID
    })
    .catch(err => {
      console.log(`${userID}: saving doc to userCreationFailed failed - wow.. `, err);
    })
    return
  }
})

exports.isRegistered = functions.region('europe-west1').https.onCall( async (data, context) => {

  const phoneNumber = data.phone

  const recipient = await admin.auth().getUserByPhoneNumber(phoneNumber)
  .catch(error => {
    return null
  })

  var uid = ""

  if (recipient.uid !== null) {
    uid = recipient.uid
  }

  return uid
})


// When user adds a new payment method, a) create a MangoPay wallet, b) create a Card Registration Object, and c) save the card token
exports.createPaymentMethodHTTPS = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid

  var mangopayID = []
  var mangopayIDString = ''
  const walletName = data.text


  await admin.firestore().collection('users').doc(userID).get().then(doc => {
    userData = doc.data();
    mangopayID.push(userData.mangopayID);
    mangopayIDString = userData.mangopayID;
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  var walletExists = false
  var walletID = ""

  // we want to know whether the user already has a wallet or not - if they don't, we'll need to create it
  await admin.firestore().collection('users').doc(userID).collection('wallets').get().then(snapshot => {

    if (snapshot.docs.length < 1) {
      // redundant but helps for clarity
      walletExists = false
    } else {
      console.log('found a wallet!')
      walletExists = true
      const foundWallet = snapshot.docs[0]
      walletID = foundWallet.id
    }
    return
  }).catch(err => {
    console.log('Error getting wallet info', err);
  });

  if (walletExists === false) {
    const wallet = await mpAPI.Wallets.create({Owners: mangopayID, Description: walletName, Currency: 'GBP'});

    walletID = wallet.Id

    // we need to add a Wallet to the user's Firestore record - this will store the card token(s) for repeat payments

    admin.firestore().collection('users').doc(userID).set({
      defaultWalletID: wallet.Id
    }, {merge: true})
    // merge: true is often crucial but perhaps nowhere more so than here.. DO NOT DELETE without extreme care
    .catch(err => {
      console.log('Error saving to database', err);
    })

    admin.firestore().collection('users').doc(userID).collection('wallets').doc(wallet.Id).set({
      created: wallet.CreationDate,
      balance: wallet.Balance['Amount'],
      description: wallet.Description,
      currency: wallet.Currency,
      // I'm not sure this line is even needed
      // temp_card_registration_id: cardReg.Id
    })
    .catch(err => {
      console.log('Error saving to database', err);
    })
  }

  // create CardRegistration object

  const cardReg = await mpAPI.CardRegistrations.create({userID: mangopayIDString, Currency: 'EUR', CardType: "CB_VISA_MASTERCARD"});

  // this function deals with steps 1-4 outlined here: https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
  // we 1) created a wallet using the mangopayID stored in Firestore (if it didn't already exist), then 2) created a CardRegistration object, and now need to return the CardRegistration object to the client as per the docs
  
  // creating a little JSON to send back to the client - the walletID is used later in the process
  const walletData = {"walletID": walletID}

  return [cardReg, walletData];

});

exports.addCardRegistration = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid

  var mangopayID = ''
  const rd = data.regData
  const cardRegID = String(data.cardRegID)
  const walletID = data.walletID

  // using the Firebase userID (supplied via 'context' of the request), get the mangopayID 
  await admin.firestore().collection('users').doc(userID).get().then(doc => {
    userData = doc.data();
    mangopayID = userData.mangopayID
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  // update the CardRegistration object with the Registration data and cardRegID sent as the argument for this function.
  // see https://docs.mangopay.com/endpoints/v2.01/cards#e1042_post-card-info 
  // "Update a Card Registration"
  const cardObject = await mpAPI.CardRegistrations.update({RegistrationData: rd, Id: cardRegID})

  admin.firestore().collection('users').doc(userID).set({
    defaultCardID: cardObject.CardId
    // merge (to prevent overwriting other fields) should never be needed, but just in case..
  }, {merge: true})
  .catch(err => {
    console.log('Error saving to database', err);
  })

  let cardID = cardObject.CardId

  // and save the important part of the response - the cardId - to the Firestore database
  admin.firestore().collection('users').doc(userID).collection('wallets').doc(walletID).collection('cards').doc(cardID).set({
    cardID: cardID
    // merge (to prevent overwriting other fields) should never be needed, but just in case..
  }, {merge: true})
  .catch(err => {
    console.log('Error saving to database', err);
  })

  return cardID
})

// the transact function is structured as follows: 1) receiving the call from client (payer) containing the recipient ID, the amount, and the currency 2) it fetches the MP wallet IDs of each party from Firestore 3) it checks the balance of each from the MP Wallet, 4) creates a MP Transfer, 5) logs a Transaction in the Firestore Transaction database (this automatically triggers updates to each party's Receipts), 6) update both payer/user and recipient balances - this may soon be deprecated in favour of calling the mangopay wallet balance directly - and 7) returns confirmation to client upon success. N.B. notification to the recipient happens elsewhere, and is triggered by the creation of a Transaction record (step 5 on this list)

exports.transact = functions.region('europe-west1').https.onCall( async (data, context) => {

  // 1: request data
  const db = admin.firestore()
  const userID = context.auth.uid
  const recipientID = data.recipientUID
  const amountRequested = data.amount
  // 98% of amount requested is transferred
  const amount = (amount*98)/100
  const currency = data.currency

  // now we have all the input we need ^

  let userRef = db.collection("users").doc(userID)
  let recipientRef = db.collection("users").doc(recipientID)

  var oldUserBalance = 0
  var oldRecipientBalance = 0

  var userWalletID = ''
  var userMangoPayID = ''
  var recipientWalletID = ''
  var recipientMangoPayID = ''

  var userFullname = ''
  var recipientFullname = ''

  // boolean flag to check the balances have been correctly fetched
  var balanceFail = false

  
  // 2: get the user and recipient  wallet ID and MP ID
  await userRef.get().then(doc => {
    let data = doc.data()
    userMangoPayID = data.mangopayID
    userFullname = data.fullname
    return userWalletID = data.defaultWalletID
    // return oldUserBalance = data.balance;
  })
  .catch(err => {
    balanceFail = true
    console.log('Error getting user balance', err);
  });
  await recipientRef.get().then(doc => {
    let data = doc.data()
    recipientMangoPayID = data.mangopayID
    recipientFullname = data.fullname
    return recipientWalletID = data.defaultWalletID
  })
  .catch(err => {
    balanceFail = true
    console.log('Error getting recipient balance', err);
  });

  // 3: Check balance of both parties
  const userMPWallet = await mpAPI.Wallets.get(userWalletID)
  .catch(err => {
    balanceFail = true,
    console.log('Error getting userMPWallet', err)
  })
  oldUserBalance = userMPWallet.Balance.Amount

  const recipientMPWallet = await mpAPI.Wallets.get(recipientWalletID)
  .catch(err => {
    balanceFail = true,
    console.log('Error getting recipientMPWallet', err)
  })
  oldRecipientBalance = recipientMPWallet.Balance.amount


  // 4: if both balances have been correctly retrieved, trigger the transaction
  if (balanceFail !== true) {

    if (amount <= oldUserBalance && amount > 0) {

      const MPTransferData =
        {
        "AuthorId": userMangoPayID,
        "CreditedUserId": recipientMangoPayID,
        "DebitedFunds": {
          "Currency": currency,
          "Amount": amount
          },
        // intraplatform transactions are free, so fee is zero
        "Fees": {
          "Currency": currency,
          "Amount": 0
          },
        "DebitedWalletId": userWalletID,
        "CreditedWalletId": recipientWalletID
        }

      const transfer = await mpAPI.Transfers.create(MPTransferData)
      .catch(err => {
        console.log(err)
        return err
      })

      // 5: Add a new document to FS transaction database with a generated id
      const transactionData = {
        from: userID,
        to: recipientID,
        datetimeHR: admin.firestore.FieldValue.serverTimestamp(),
        datetime: Math.round(Date.now()/1000),
        currency: currency,
        amount: amount
      }

      db.collection('transactions').add(transactionData)

      // 6: update both party's wallets
      const newUserWallet = await mpAPI.Wallets.get(userWalletID)
      const newUserBalance = newUserWallet.Balance.Amount

      const newRecipientWallet = await mpAPI.Wallets.get(recipientWalletID)
      const newRecipientBalance = newRecipientWallet.Balance.Amount

      userRef.set({balance: newUserBalance}, {merge: true})
      recipientRef.set({balance: newRecipientBalance}, {merge: true})

      // 7: return success to Client

      const receiptData = {
        "amount": amount,
        "currency": currency,
        "datetime": Math.round(Date.now()/1000),
        "payerID": userID,
        "recipientID": recipientID,
        "payerName": userFullname,
        "recipientName": recipientFullname,
        "userIsPayer": true
      }

      return receiptData
    } else {
      console.log("user does not have sufficient funds")
      return { text: "user does not have sufficient funds"}
    }
  } else {
    // TODO there was an error getting one of the balances - abort transaction and inform user
    console.log('one or more of the balances was not retrieved')
    return { text: "balance retrieval failed" }
  }
})

// TODO this func doesn't really need to go through cloud functions, could be moved to client
exports.listCards = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid
  var mangopayID = ""

  // using the Firebase userID (supplied via 'context' of the request), get the mangopayID 
  await admin.firestore().collection('users').doc(userID).get().then(doc => {
    userData = doc.data();
    mangopayID = userData.mangopayID
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  if (mangopayID !== "") {
    const cardsList = await mpAPI.Users.getCards(mangopayID, JSON)

    return cardsList
  } else {
    return null
  }
})

exports.createPayin = functions.region('europe-west1').https.onCall( async (data, context) => {
  const userID = context.auth.uid

  var mangopayID = ''
  var walletID = ''
  var cardID = ''
  var billingAddress = {
    "AddressLine1": '',
    "AddressLine2": '',
    "City": '',
    "Region": '',
    "PostalCode": '',
    "Country": ''
  }
  var culture = ''

  const currencyType = data.currency
  const amount = data.amount + 20
  // the fee to be taken should be an integer, since the amount is in cents/pence

  // payin billing is applied here: 2% + 20p
  const fee = (amount*98)/100 + 20

  // using the Firebase userID (supplied via 'context' of the request), get the data we need for the payin 
  await admin.firestore().collection('users').doc(userID).get().then(doc => {
    userData = doc.data();
    mangopayID = userData.mangopayID
    walletID = userData.defaultWalletID
    cardID = userData.defaultCardID

    billingAddress["AddressLine1"] = userData.defaultBillingAddress.line1
    billingAddress["AddressLine2"] = userData.defaultBillingAddress.line2
    billingAddress["City"] = userData.defaultBillingAddress.city
    billingAddress["Region"] = userData.defaultBillingAddress.region
    billingAddress["PostalCode"] = userData.defaultBillingAddress.postcode
    billingAddress["Country"] = userData.defaultBillingAddress.country

    culture = userData.culture
    return
  })
  .catch(err => {
    console.log('Error getting user info for credit topup', err);
  });

  // for reference: 
  // "Billing": {
  //   "Address": {
  //   "AddressLine1": "1 Mangopay Street",
  //   "AddressLine2": "The Loop",
  //   "City": "Paris",
  //   "Region": "Ile de France",
  //   "PostalCode": "75001",
  //   "Country": "FR"
  //   }
  // },

  const payinData = {
      "AuthorId": mangopayID,
      "CreditedWalletId": walletID,
      "DebitedFunds": {
        "Currency": currencyType,
        "Amount": amount
        },
      "Fees": {
        // TODO: what currency should fees be taken in? 
        "Currency": currencyType,
        "Amount": fee
        },
      // if 3DSecure or some other flow is triggered, the user is redirected to this URL on completion (which should redirect them back to the app, I guess?)
      "SecureModeReturnURL": "http://www.my-site.com/returnURL",
      "CardId": cardID,
      // Secure3D flow can be triggered manually if required, but is mandatory for all payins over 50 EUR regardless. Leaving as default for now
      "CardType": "CB_VISA_MASTERCARD",
      "SecureMode": "DEFAULT",
      "StatementDescriptor": "WILDFIRE",
      "Billing": {
        "Address": billingAddress
      },
      "Culture": culture,
      "PaymentType": "CARD",
      "ExecutionType": "DIRECT"
      }

  const payin = mpAPI.PayIns.create(payinData)

  return payin
})

// exports.createPayout = functions.region('europe-west1').https.onCall( async (data, context) => {

//   const userID = context.auth.uid
//   const currencyType = data.currency
//   const amountRequested = data.amount
//   const amount = (amountRequested*98)/100 
//   // the fee to be taken should be an integer, since the amount is in cents/pence
//   // UK fee (at time of writing) is 45 pence
//   const fee = 45
  
//   Math.round(amount/100*1.8)

//   var mangopayID = ''
//   var walletID = ''
//   var bankAccountID = ''
//   var culture = ''

//   // using the Firebase userID (supplied via 'context' of the request), get the data we need for the payin 
//   await admin.firestore().collection('users').doc(userID).get().then(doc => {
//     userData = doc.data();
//     mangopayID = userData.mangopayID
//     walletID = userData.defaultWalletID
//     bankAccountID = userData.defaultBankAccountID
    
//     culture = userData.culture
//     return
//   })
//   .catch(err => {
//     console.log('Error getting user info for payout', err);
//   });

//   const payoutData = {
//     "AuthorId": mangopayID,
//     "DebitedFunds": {
//       "Currency": currencyType,
//       "Amount": amount
//       },
//     "Fees": {
//       "Currency": currencyType,
//       "Amount": fee
//       },
//     "BankAccountId": bankAccountID,
//     "DebitedWalletId": walletID,
//     "BankWireRef": "WILDFIRE",
//     "PaymentType": "BANK_WIRE"
//     }

//   const payout = mpAPI.PayOuts.create(payoutData)
//   return payout
// })

exports.getCurrentBalance = functions.region('europe-west1').https.onCall( async (data, context) => {

  // TODO in future, this func should probably be triggered by webhook or similiar, rather than relying on a call from client

  var userID = context.auth.uid
  // if the userID isn't available, that's likely because it's a request via helpers.callCloudFunction
  if (userID === null) {
    userID = data.uid
  }
  const db = admin.firestore().collection('users').doc(userID)

  var walletID = ""

  // using the Firebase userID (supplied via 'context' of the request), get the wallet ID
  await db.get().then(doc => {
    userData = doc.data();
    walletID = userData.defaultWalletID
    return
  })
  .catch(err => {
    console.log('Error getting defaultWalletID', err);
  });

  
  const wallet = await mpAPI.Wallets.get(walletID)
  const currentBalance = wallet.Balance.Amount

  const balanceFactored = (currentBalance*100)/98

  db.set({balance: balanceFactored}, {merge: true})

  return balanceFactored

});

// exports.addCardRegistration = functions.region('europe-west1').https.onCall( async (data, context) => {

//   const userID = context.auth.uid

//   var mangopayID = ''
//   const rd = data.regData
//   const cardRegID = String(data.cardRegID)
//   const walletID = data.walletID

//   // using the Firebase userID (supplied via 'context' of the request), get the mangopayID 
//   await admin.firestore().collection('users').doc(userID).get().then(doc => {
//     userData = doc.data();
//     mangopayID = userData.mangopayID
//     return
//   })
//   .catch(err => {
//     console.log('Error getting userID', err);
//   });

//   // update the CardRegistration object with the Registration data and cardRegID sent as the argument for this function.
//   // see https://docs.mangopay.com/endpoints/v2.01/cards#e1042_post-card-info 
//   // "Update a Card Registration"
//   const cardObject = await mpAPI.CardRegistrations.update({RegistrationData: rd, Id: cardRegID})

//   admin.firestore().collection('users').doc(userID).set({
//     defaultCardID: cardObject.CardId
//     // merge (to prevent overwriting other fields) should never be needed, but just in case..
//   }, {merge: true})
//   .catch(err => {
//     console.log('Error saving to database', err);
//   })

//   let cardID = cardObject.CardId

//   // and save the important part of the response - the cardId - to the Firestore database
//   admin.firestore().collection('users').doc(userID).collection('wallets').doc(walletID).collection('cards').doc(cardID).set({
//     cardID: cardID
//     // merge (to prevent overwriting other fields) should never be needed, but just in case..
//   }, {merge: true})
//   .catch(err => {
//     console.log('Error saving to database', err);
//   })

//   return cardID
// })


exports.addBankAccount = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid
  const db = admin.firestore().collection('users').doc(userID)

  var mangopayID = ""

  const name = data.name
  const swiftCode = data.swiftCode
  const accountNumber = data.accountNumber

  const line1 = data.line1
  const line2 = data.line2
  const city = data.city
  const region = data.region
  const postcode = data.postcode
  const countryCode = data.countryCode
  
  // using the Firebase userID (supplied via 'context' of the request), get the wallet ID
  await db.get().then(doc => {
    userData = doc.data();
    
    mangopayID = userData.mangopayID
    
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  const bankAccountData = {
    Type: 'OTHER',
    "OwnerName": name,
    "Country": countryCode,
    // N.B. BIC is equivalent to SWIFT code
    "BIC": swiftCode,
    "AccountNumber": accountNumber,

    "OwnerAddress": {
      "AddressLine1": line1,
      "AddressLine2": line2,
      "City": city,
      "Region": region,
      "PostalCode": postcode,
      "Country": countryCode
    }
    
  }

  const bankAccountMP = await mpAPI.Users.createBankAccount(mangopayID, bankAccountData)

  admin.firestore().collection('users').doc(userID).set({
    defaultBankAccountID: bankAccountMP.Id
    // merge (to prevent overwriting other fields) should never be needed, but just in case..
  }, {merge: true})
  .catch(err => {
    console.log('Error saving to database', err);
  })

  return
})

// TODO this func doesn't really need to go through cloud functions, could be moved to client
exports.listBankAccounts = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid
  var mangopayID = ""

  // using the Firebase userID (supplied via 'context' of the request), get the mangopayID 
  await admin.firestore().collection('users').doc(userID).get().then(doc => {
    userData = doc.data();
    mangopayID = userData.mangopayID
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  if (mangopayID !== "") {
    const accountsList = await mpAPI.Users.getBankAccounts(mangopayID)
    return accountsList
  } else {
    return null
  }
})

exports.triggerPayout = functions.region('europe-west1').https.onCall( async (data, context) => {

  var userID = context.auth.uid
  // if the userID isn't available, that's likely because it's a request via helpers.callCloudFunction
  if (userID === null) {
    userID = data.uid
  }

  const db = admin.firestore().collection('users').doc(userID)

  var walletID = ""
  var mangopayID = ""
  var bankAccountID = ""

  // TODO currency likely to be an issue. At present it's defined in the initial call from client (reasoning: user can choose their currrency and later switch at will) but if the currency doesn't match the wallet currency, the payout won't succeed. Thought needed. 
  const currencyType = data.currency
  const amountRequested = data.amount
  const amount = (amountRequested*98)/100 
  
  // the fee to be taken should be an integer, since the amount is in cents/pence
  const fee = 45
  
  // using the Firebase userID (supplied via 'context' of the request), get the wallet ID
  await db.get().then(doc => {
    userData = doc.data();
    
    mangopayID = userData.mangopayID
    walletID = userData.defaultWalletID

    bankAccountID = userData.defaultBankAccountID
    
    return
  })
  .catch(err => {
    console.log('Error getting mangopayID from Firestore database', err);
  });

  const payoutData = 
    {
    "AuthorId": mangopayID,
    "DebitedFunds": {
      "Currency": currencyType,
      "Amount": amount
      },
    "Fees": {
      "Currency": currencyType,
      "Amount": fee
      },
    "BankAccountId": bankAccountID,
    "DebitedWalletId": walletID,
    "BankWireRef": "WILDFIRE",
    "PaymentType": "BANK_WIRE"
    }

    return payout = await mpAPI.PayOuts.create(payoutData)
})

exports.addKYCDocument = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid

  const pages = data.pages
  
  const mangopayID = data.mangopayID

  // // using the Firebase userID (supplied via 'context' of the request), get the data we need for the payin 
  // await admin.firestore().collection('users').doc(userID).get().then(doc => {
  //   userData = doc.data();
  //   mangopayID = userData.mangopayID
  //   return
  // })
  // .catch(err => {
  //   console.log('Error getting user info for payout', err);
  // });

  const parameters = {
    "Type": "IDENTITY_PROOF"
  }


  // KYC docs: https://docs.mangopay.com/endpoints/v2.01/kyc-documents#e204_the-kyc-document-object
  
  // step 1: create the kyc doc for the user (status: "CREATED")
  const kycDoc = await mpAPI.Users.createKycDocument(mangopayID, parameters)

  const kycDocID = kycDoc.Id
  console.log(kycDocID)

  // step 2: create a 'page' for each image to upload. Passports only require 1 image, but Driver's licences, for example, require 2: Front and Back


  if (pages === 1) {
    console.log('there is one page')
    const base64Image = data.base64Image

    const file = {
      "File": base64Image
    }
    const onePageDoc = await mpAPI.Users.createKycPage(mangopayID, kycDocID, file)
    console.log(onePageDoc)
  } else {
    const firstBase64Image = data.firstBase64Image
    const secondBase64Image = data.secondBase64Image

    const frontFile = {
      "File": firstBase64Image
    }

    const backFile = {
      "File": secondBase64Image
    }

    console.log('there are two pages')
    // await on the second, not the first, in an attempt to save time..
    const firstPage = mpAPI.Users.createKycPage(mangopayID, kycDoc.Id, frontFile)
    const secondPage = await mpAPI.Users.createKycPage(mangopayID, kycDoc.Id, backFile)
  }


  // step 3: upon successful creation of kyc page(s) i.e. upload of images in base64 format, update kyc document status to 'Validation Asked'
  const requestValidationStatus = {
    "Id": kycDocID,
    "Status": "VALIDATION_ASKED"
  }

  const updatedDoc = await mpAPI.Users.updateKycDocument(mangopayID, requestValidationStatus)

  return updatedDoc
})

// messy name is a little extra security by obscurity - this endpoint has no authentication
exports.events_FCHK4JM41QgvlwAqzUGHmD89JiH2f0
= functions.region('europe-west1').https.onRequest(async (request, response) => {

  const db = admin.firestore().collection('events')
  
  // key info received is here
  let eventType = request.query.EventType
  let resourceID = request.query.RessourceId

  // let's differentiate between the types of triggers that can be received
  if (eventType === "KYC_SUCCEEDED") {
    db.doc('KYC_SUCCEEDED').collection('eventQueue').add({
      eventType: eventType,
      resourceID: resourceID
    }).then(ref => {
      response.send('success')
      return
    }).catch(err => {
      console.log('Error saving KYC_SUCCEEDED event', err);
    })

  } else if (eventType === "KYC_FAILED") {

    db.doc('KYC_FAILED').collection('eventQueue').add({
      eventType: eventType,
      resourceID: resourceID
    }).then(ref => {
      response.send('success')
      return
    }).catch(err => {
      console.log('Error saving KYC_FAILED event', err);
    })

  } else if (eventType === "TRANSFER_NORMAL_SUCCEEDED") {

    db.doc('TRANSFER_NORMAL_SUCCEEDED').collection('eventQueue').add({
      eventType: eventType,
      resourceID: resourceID
    }).then(ref => {
      response.send('success')
      return
    }).catch(err => {
      console.log('Error saving TRANSFER_NORMAL_SUCCEEDED event', err);
    })

  } else if (eventType === "PAYIN_NORMAL_SUCCEEDED") {

    db.doc('PAYIN_NORMAL_SUCCEEDED').collection('eventQueue').add({
      eventType: eventType,
      resourceID: resourceID
    }).then(ref => {
      response.send('success')
      return
    }).catch(err => {
      console.log('Error saving PAYIN_NORMAL_SUCCEEDED event', err);
    })

  } else if (eventType === "PAYOUT_NORMAL_SUCCEEDED") {

    db.doc('PAYOUT_NORMAL_SUCCEEDED').collection('eventQueue').add({
      eventType: eventType,
      resourceID: resourceID
    }).then(ref => {
      response.send('success')
      return
    }).catch(err => {
      console.log('Error saving PAYOUT_NORMAL_SUCCEEDED event', err);
    })
  }
})

// function to handle what happens when a new eventRecord is created
exports.respondToEventRecord = functions.region('europe-west1').firestore.document('events/{type}/eventQueue/{record}').onCreate(async (snap, context) => {

  const db = admin.firestore()

  const eventType = String(context.params.type)
  const resourceID = snap.data().resourceID
  
  const eventRecord = context.params.record

  if (eventType === "KYC_SUCCEEDED") {
    // use the resourceID to get the relevant object
    const kyc = await mpAPI.KycDocuments.get(resourceID)

    // we need two things - the status (to check that the doc is validated and also to ensure the request didn't come from a 3rd party), and the mangopayID to send a notification to the correct device and user
    const status = kyc.Status
    const mangopayID = kyc.UserId


    if (status === "VALIDATED") {

      // this will hold the correct token for the user, once it's found in the database
      var KYCValidatedNotificationToken = ""

      // search for the user with that mangopayID
      await db.collection('users').where('mangopayID', '==', mangopayID).get().then(snapshot => {

        if (snapshot.empty) {

          helpers.moveEventRecordTo(eventType, 'couldNotFindMangopayID', eventRecord, resourceID)

        } else {
          // there should only be one user returned by the .where() function
          snapshot.forEach(doc => {
            const data = doc.data()
            KYCValidatedNotificationToken = data.fcmToken
          })
        }
        return 
      }).catch(err => {

        helpers.moveEventRecordTo(eventType, 'couldNotFetchUsers', eventRecord, resourceID, false, err)

      }) 

      // Notification details.
      const payload = {
        notification: {
          title: 'Your ID has been verified!',
          body: 'You can now deposit funds to your bank account'
          // icon: photoURL
        },
        data: {
          eventType: eventType
        },
        token: KYCValidatedNotificationToken
      }

      // Send a message to the device corresponding to the provided
      // registration token.
      admin.messaging().send(payload)
        .then((response) => {
          // TEMPORARILY MOVING RECORD INSTEAD OF DELETION - this can probably be switched back at some point

          // let deleteDoc = db.collection('events').doc(eventType).collection('eventQueue').doc(eventRecord).delete()
          helpers.moveEventRecordTo(eventType,'successful',eventRecord,resourceID, false,'testing')
          return
      })
      .catch((err) => {

        helpers.moveEventRecordTo(eventType, 'failedToSendNotification', eventRecord, resourceID, false, err)

      })
    } else {

      // this means we received a ping to tell us validation was successful, but upon closer inspection, the status of the KYC doc is not VALIDATED. Hopefully this will never happen.

      helpers.moveEventRecordTo(eventType, 'KYCWasNotValidated', eventRecord, resourceID, true)

    }


  } else if (eventType === "KYC_FAILED") {
    // use the resourceID to get the relevant object
    const kyc = await mpAPI.KycDocuments.get(resourceID)

    // we need two things - the status (to check that the doc is validated and also to ensure the request didn't come from a 3rd party), and the mangopayID to send a notification to the correct device and user
    const status = kyc.Status
    const mangopayID = kyc.UserId
    const refusedType = kyc.RefusedReasonType.toString()
    var refusedMessage = ""
    if (kyc.RefusedReasonMessage !== null) {
      refusedMessage = kyc.RefusedReasonMessage.toString()
    }



    if (status === "REFUSED") {

      // this will hold the correct token for the user, once it's found in the database
      var KYCRefusedNotificationToken = ""

      // search for the user with that mangopayID
      await db.collection('users').where('mangopayID', '==', mangopayID).get().then(snapshot => {

        if (snapshot.empty) {
          helpers.moveEventRecordTo(eventType, 'couldNotFindMangopayID', eventRecord, resourceID)
        } else {
          // there should only be one user returned by the .where() function
          snapshot.forEach(doc => {
            const data = doc.data()
            KYCRefusedNotificationToken = data.fcmToken
          })
        }
        return 
      }).catch(err => {
        helpers.moveEventRecordTo(eventType, 'couldNotFetchUsers', eventRecord, resourceID, false, err)
      }) 

      // Notification details.
      const payload = {
        notification: {
          title: 'Your ID verification could not be accepted',
          body: 'Sorry about this. More details in the app.'
          // icon: photoURL
        },
        data: {
          eventType: eventType,
          refusedType: refusedType,
          refusedMessage: refusedMessage
        },
        token: KYCRefusedNotificationToken
      }

      
      // Send a message to the device corresponding to the provided registration token
      admin.messaging().send(payload)
        .then((response) => {
          return
      })
      .catch((err) => {
        console.log(err)
        // TODO include the err in the moveEventRecordTo method instead of console.log()
        helpers.moveEventRecordTo(eventType, 'failedToSendNotification', eventRecord, resourceID, false)
      })
    } else {

      // this means we received a ping to tell us validation failed, but upon closer inspection, the status of the KYC doc is not REFUSED. Hopefully this will never happen.

      helpers.moveEventRecordTo(eventType, 'KYCWasNotRefused', eventRecord, resourceID, true)

    }
  } else if (eventType === "TRANSFER_NORMAL_SUCCEEDED") {

    // use the resourceID to get the relevant object
    const kyc = await mpAPI.Transfers.get(resourceID)

    // we need two things - the status (to check that the doc is validated and also to ensure the request didn't come from a 3rd party), and the mangopayID to send a notification to the correct device and user
    const authorID = kyc.AuthorId
    const creditorID = kyc.CreditedUserId
    const creditedFunds = kyc.CreditedFunds
    const currencyCode = creditedFunds["Currency"]
    var currency = ""

    if (currencyCode === "EUR") {
      currency = "€"
    } else if (currencyCode === "GBP") {
      currency = "£"
    } else if (currencyCode === "USD" || currencyCode === "CAD" || currencyCode === "AUD" || currencyCode === "NZD") {
      currency = "$"
    } else {
      currency = currencyCode
    }

    // amount is stored in cents/pence, so needs to be divided by 100
    const centsAmount = parseFloat(creditedFunds["Amount"])
    const amount = String(centsAmount/100)

    var authorName = ""
    var creditorToken = ""

    
    // finding the authorID name
    // search for the user with that mangopayID
    await db.collection('users').where('mangopayID', '==', authorID).get().then(snapshot => {

      if (snapshot.empty) {

        helpers.moveEventRecordTo(eventType, 'couldNotFindAuthorID', eventRecord, resourceID)

      } else {
        // there should only be one user returned by the .where() function
        snapshot.forEach(doc => {
          const data = doc.data()
          authorName = data.fullname
        })
      }
      return 
    }).catch(err => {

      helpers.moveEventRecordTo(eventType, 'couldNotFetchUsersToFindAuthorID', eventRecord, resourceID, false, err)

    }) 
    // finding the creditorID token
    // search for the user with that mangopayID
    await db.collection('users').where('mangopayID', '==', creditorID).get().then(snapshot => {

      if (snapshot.empty) {

        helpers.moveEventRecordTo(eventType, 'couldNotFindCreditorID', eventRecord, resourceID)

      } else {
        // there should only be one user returned by the .where() function
        snapshot.forEach(doc => {
          const data = doc.data()
          creditorToken = data.fcmToken
        })
      }
      return 
    }).catch(err => {

      helpers.moveEventRecordTo(eventType, 'couldNotFetchUsersToFindCreditorToken', eventRecord, resourceID, false, err)

    }) 

    // Notification details to be sent to the Creditor (not the author, who already knows about it)
    const payload = {
      notification: {
        title: `You received ${currency}${amount} from ${authorName}!`,
        body: 'Open the app to view receipt.',
        // icon: photoURL
      },
      data: {
        eventType: eventType,
        authorName: authorName,
        currency: currency,
        amount: amount
      },
      token: creditorToken
    }

    // Send a message to the device corresponding to the provided
    // registration token.
    admin.messaging().send(payload)
      .then((response) => {
        // let deleteDoc = db.collection('events').doc(eventType).collection('eventQueue').doc(eventRecord).delete()
        helpers.moveEventRecordTo(eventType,'successful',eventRecord,resourceID, false,'testing')
        return
    })
    .catch((err) => {
  
      console.log(err)

      helpers.moveEventRecordTo(eventType, 'failedToSendNotification', eventRecord, resourceID, false)

    })
  }
})

// when a user is deleted, set isDeleted flag to True in the database
exports.deleteUser = functions.region('europe-west1').https.onCall( async (data, context) => {

  const userID = context.auth.uid
  const userRef = admin.firestore().collection('users').doc(userID)

  var resultOutput = ""

  var currentBalance = await helpers.callCloudFunction('getCurrentBalance', {uid: userID})
  .then( () => {
    resultOutput = "got current balance"

    if (currentBalance > 50) {
      return helpers.callCloudFunction('triggerPayout', {currency: 'GBP', amount: currentBalance, uid: userID})
    } else {
      return null
    }
  }).then( (result) => {
    if (result === null) {
      resultOutput = "triggered payout (but insufficient credit, so no payout was made)"
    } else {
      resultOutput = "triggered payout"
    }
    // delete user in Firebase Authentication
    return admin.auth().deleteUser(uid)
  }).then( () => {
    resultOutput = "deleted User in Auth"
    // delete user in Firestore database
    userRef.delete()
    console.log('currentBalance in function flow is: ' + currentBalance)
    return console.log(`Successfully deleted user ${userID}`)
  }).catch( error => {
    resultOutput = error
    console.log(`deleteUser func: ${userID} tried to delete account, but there was an error: `, error)
  })

  console.log('currentBalance outside function flow is: ' + currentBalance)
  return resultOutput
})

// Since all users exist in the database as a kind of duplicate of the User list, when a user deletes their account, rather than delete the record we're just adding an isDeleted flag - if the user ever wants to return their data is still available

exports.deleteCard = functions.region('europe-west1').https.onCall( async (data, context) => {

  const db = admin.firestore()

  const uid = context.auth.uid
  const userRef = db.collection("users").doc(uid)

  var cardID = ""

  var output = await userRef.get().then(doc => {
    let data = doc.data()
    cardID = data.defaultCardID
    return
  })
  .then(() => mpAPI.Cards.update({Id: cardId, Active: false}))
  .then(() => {
    userRef.doc('wallets'/{walletID}/'cards'/cardID).delete()
    userRef.set({
      defaultCardID: ""
    }, {merge: true})
    console.log(output)
    return
  }).catch(error => {
    console.log(`deleteCard func: ${userID} tried to delete card, but there was an error: `, error)
  })

  return output
})

exports.deleteBankAccount = functions.region('europe-west1').https.onCall( async (data, context) => {
  const db = admin.firestore()

  const uid = context.auth.uid
  const userRef = db.collection("users").doc(uid)

  var mangopayID = ""
  var bankAccountID = ""

  var output = await userRef.get().then(doc => {
    let data = doc.data()
    mangopayID = data.mangopayID
    bankAccountID = data.defaultBankAccountID
    return
  })
  .then(() => mpAPI.Users.deactivateBankAccount(mangopayID, bankAccountID))
  .then(() => {
    userRef.set({
      defaultBankAccountID: ""
    }, {merge: true})
    console.log(output)
    return
  })
  .catch(error => {
    console.log(`deleteBackAccount func: ${userID} tried to delete Bank Account info, but there was an error: `, error)
  })

  return output
})