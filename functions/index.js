// File to manage all Cloud Functions
// Only use Cloud Firestore! Not Realtime database, and watch out for the different methods required


// Dependancies
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const gcs = require('@google-cloud/storage');
const mangopay = require('mangopay2-nodejs-sdk');

const mpAPI = new mangopay({
                       clientId: 'wildfirewallet',
                       clientApiKey: 'cwSQuWi9RCbnr5Fh5HktxevT9ch0pK3wWUn4t5rHJkCP1KSCiu'
                       // Set the right production API url. If testing, omit the property since it defaults to sandbox URL
                       // baseUrl: 'https://api.mangopay.com'
                       });
const creds = {
  clientId: 'wildfirewallet',
  clientApiKey: 'cwSQuWi9RCbnr5Fh5HktxevT9ch0pK3wWUn4t5rHJkCP1KSCiu'
}

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

  var firstname = data.firstname
  var lastname = data.lastname
  var email = data.email
  var birthday = data.dob
  var nationality = data.nationality
  var residence = data.residence

  const customer = await mpAPI.Users.create({PersonType: 'NATURAL', FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email});

  return admin.firestore().collection('users').doc(context.params.id).update({mangopayID: customer.Id});

})

// TODO rename this function!

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
      const wallet = await mpAPI.Wallets.create({Owners: mangopayID, Description: walletName, Currency: 'EUR'});

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
    const amount = data.amount
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

        console.log(MPTransferData)

        const transfer = await mpAPI.Transfers.create(MPTransferData)
        .catch(err => {
          console.log(err)
          return err
        })
        console.log(transfer)

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

      // // runTransaction is a Firebase thing - designed for this kind of use case
      // let transaction = db.runTransaction(t => {
      //   // return t.get(userRef)
      //   //   .then(doc => {
        
      //   // here's the magic
      //   if (amount <= oldUserBalance && amount > 0) {
              
      //     // P.S. the sendAmount > 0 should always pass since there will be validation elsewhere. However, suggest leaving it in as it doesn't hurt and if the FE validation ever breaks for whatever reason, allowing sendAmount < 0 would be a catastrophic security issue i.e. this is a useful failsafe
          
      //     let newUserBalance = oldUserBalance - amount
      //     let newRecipientBalance = oldRecipientBalance + amount

      //     // update both parties' balances
      //     t.update(userRef, {balance: newUserBalance});
      //     t.update(recipientRef, {balance: newRecipientBalance})
          
      //     // Add a new document with a generated id.
      //     return db.collection('transactions').add(transactionData)
      //   } else {
      //     return nil        
      //   }
      // }).then(result => {
      //   // this transaction will only complete if both parties' balances are updated
      //   console.log('Transaction success!');
      //   return { text: "success" };
      // }).catch(err => {
      //   console.log('Transaction failure:', err);
      //   return { text: "failure" };
      // });
    // }
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
    return cardsList = mpAPI.Users.getCards(mangopayID, JSON)

  })

  exports.addCredit = functions.region('europe-west1').https.onCall( async (data, context) => {
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
    const amount = data.amount
    // the fee to be taken should be an integer, since the amount is in cents/pence
    const fee = Math.round(amount/100*1.8)

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

  exports.createPayout = functions.region('europe-west1').https.onCall( async (data, context) => {

    const userID = context.auth.uid
    const currencyType = data.currency
    const amount = data.amount
    // the fee to be taken should be an integer, since the amount is in cents/pence
    const fee = Math.round(amount/100*1.8)

    var mangopayID = ''
    var walletID = ''
    var bankAccountID = ''
    var culture = ''

    // using the Firebase userID (supplied via 'context' of the request), get the data we need for the payin 
    await admin.firestore().collection('users').doc(userID).get().then(doc => {
      userData = doc.data();
      mangopayID = userData.mangopayID
      walletID = userData.defaultWalletID
      bankAccountID = userData.defaultBankAccountID
      
      culture = userData.culture
      return
    })
    .catch(err => {
      console.log('Error getting user info for payout', err);
    });

    const payoutData = {
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

    const payout = mpAPI.PayOuts.create(payoutData)
    return payout
  })

  exports.getCurrentBalance = functions.region('europe-west1').https.onCall( async (data, context) => {

    // TODO in future, this func should probably be triggered by webhook or similiar, rather than relying on a call from client

    const userID = context.auth.uid
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

    return db.set({balance: currentBalance}, {merge: true})

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
      console.log('Error getting userID', err);
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
    return cardsList = mpAPI.Users.getBankAccounts(mangopayID)

  })

  exports.triggerPayout = functions.region('europe-west1').https.onCall( async (data, context) => {

    const userID = context.auth.uid
    const db = admin.firestore().collection('users').doc(userID)

    var walletID = ""
    var mangopayID = ""
    var bankAccountID = ""

    // TODO currency likely to be an issue. At present it's defined in the initial call from client (reasoning: user can choose their currrency and later switch at will) but if the currency doesn't match the wallet currency, the payout won't succeed. Thought needed. 
    const currencyType = data.currency
    const amount = data.amount
    
    // the fee to be taken should be an integer, since the amount is in cents/pence
    const fee = Math.round(amount/100*1.8)
    
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

    // let bankAccounts = mpAPI.Users.getBankAccount(mangopayID)
    // console.log(bankAccounts)
    // let primaryBankAccount = bankAccounts[1]
    // console.log('primaryBankAccount')
    // let bankAccountID = primaryBankAccount["Id"]
    // console.log('bankAccountID')

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

  exports.deleteCard = functions.region('europe-west1').https.onCall( async (data, context) => {

    // const userID = context.auth.uid
    // var mangopayID = ""

    // // using the Firebase userID (supplied via 'context' of the request), get the mangopayID 
    // await admin.firestore().collection('users').doc(userID).collection('wallets').doc(get().then(doc => {
    //   userData = doc.data();
    //   mangopayID = userData.mangopayID
    //   return
    // })
    // .catch(err => {
    //   console.log('Error getting mangopayID from Firestore database', err);
    // })

    // TODO add MangoPay Card Deactivation (useful code above)


    return cardsList = mpAPI.Users.getCards(mangopayID, JSON)

  })

  // messy name is a little extra security by obscurity - this endpoint has no authentication
  exports.events = functions.region('europe-west1').https.onRequest(async (request, response) => {

    let eventType = request.query.EventType
    let resourceID =request.query.RessourceId

    if (eventType === "KYC_SUCCEEDED") {

      const kyc = await mpAPI.KycDocuments.get(resourceID)
      const status = kyc.Status

      if (status === "VALIDATED") {

        // send notification to client (also need the mangopay userID for this)

      }

    } else if (eventType === "KYC_FAILED") {
      
      const kyc = await mpAPI.KycDocuments.get(resourceID)
      const status = kyc.Status
      
    }

    response.send("success");
  })


//// when a user is deleted, set isDeleted flag to True in the database
//exports.cleanupUserData = functions.auth.user().onDelete((userRecord,context) => {
//    const uid = userRecord.uid
//    const doc = admin.firestore().doc('/users/' + uid)
//    return doc.update({isDeleted: true})
//    })
//
//// need to add the payment processor side deletion as well as Firestore deletion - have attached the following as a guide
//// When a user deletes their account, clean up after them
//exports.cleanupUser = functions.auth.user().onDelete(async (user) => {
//                                                     const snapshot = await admin.firestore().collection('stripe_customers').doc(user.uid).get();
//                                                     const customer = snapshot.data();
//                                                     await stripe.customers.del(customer.customer_id);
//                                                     return admin.firestore().collection('stripe_customers').doc(user.uid).delete();
//                                                     });

// Since all users exist in the database as a kind of duplicate of the User list, when a user deletes their account, rather than delete the record we're just adding an isDeleted flag - if the user ever wants to return their data is still available