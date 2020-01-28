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


// the thinking behind having this function here rather than on client is that any functionality concerned with transactions should be a Cloud Function so that any necessary fixes can be applied immediately in realtime
exports.addZeroBalanceOnCreation = functions.region('europe-west1').firestore
  .document('users/{userId}')
  .onCreate((snap, context) => {
    // get a ref to the doc
    const docRef = context.params.userId

    // add a field called 'balance' and set it to 0
    // this func is only called onCreate i.e. the very first time a user logs in with this phone number
    return admin.firestore().collection('users').doc(docRef).update({balance: 0})
  });

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

// this was an experiment - unlikely to work, but haven't tried it yet
    // let payerName = payerDocRef.firstname
    // let recipientName = recipientDocRef.firstname

    // get the payer name 
    await payerDocRef.get().then(doc => {
      return payerName = doc.data().firstname + " " + doc.data().lastname;
    })
    .catch(err => {
      balanceFail = true
      console.log('Error getting payer name', err);
    });

    // get the recipient name
    await recipientDocRef.get().then(doc => {
      return recipientName = doc.data().firstname + " " + doc.data().lastname;
    })
    .catch(err => {
      balanceFail = true
      console.log('Error getting recipient name', err);
    });

    // pull the transaction Data to be added to both the payer and recipient transaction subcollections
    const transactionData = {
      payerID: data.from,
      payerName: payerName,
      recipientID: data.to,
      recipientName: recipientName,
      datetime: data.datetime,
      //currency: data.currency,
      amount: data.amount

    };

    // within the 'receipts' subcollection for the payer and recipient user docs, we add a doc with the transactionID
    return payerDocRef.collection('receipts').doc(transactionID).set(transactionData), newRecipientTransaction = recipientDocRef.collection('receipts').doc(transactionID).set(transactionData)
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

  console.log(customer.Id)

  return admin.firestore().collection('users').doc(context.params.id).update({mangopayID: customer.Id});

})

// // When a user is created, register them with MangoPay and add an empty PaymentMethods collection
// exports.createNewMangopayCustomerONCALL = functions.region('europe-west1').https.onCall( async (data, context) => {

//   // TODO if this func fails for whatever reason, it should be retried (data is already in Firestore database)
  
//   const userID = context.auth.uid

//   await admin.firestore().collection('users').doc(userID).get().then(doc => {

//     userData = doc.data()
//     console.log(userData)
   
//     const firstname = userData.firstname
//     const lastname = userData.lastname
//     const email = userData.email
//     const birthday = userData.dob
//     const nationality = userData.nationality
//     const residence = userData.residence

//     // this call to MangoPay includes a response, saved as customer - we take the ID contained therein and write to Firestore database in the next step
//     const customer = await mpAPI.Users.create({PersonType: 'NATURAL', FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email}).then(docco => {

//     });

//     return admin.firestore().collection('users').doc(context.params.id).update({mangopayID: customer.Id})

//     )

    
//   })
//   .catch(err => {
//     console.log('Error getting userID', err);
//   });



// })

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
      console.log('Error getting userID', err);
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
      console.log('Error getting userID', err);
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

      return admin.firestore().collection('users').doc(userID).collection('wallets').doc(wallet.Id).set({
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



    // create Wallet and CardRegistration objects

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


    // and save the important part of the response - the cardId - to the Firestore database
    return admin.firestore().collection('users').doc(userID).collection('wallets').doc(walletID).collection('cards').doc(cardObject.CardId).set({
      cardID: cardObject.CardId
      // merge (to prevent overwriting other fields) should never be needed, but just in case..
    }, {merge: true})
    .catch(err => {
      console.log('Error saving to database', err);
    })
  })

  // transact function needs to also log the transaction in Firestore
  exports.transact = functions.https.onCall( async (data, context) => {
    //        let recipientRef = self.db.collection("users").document(self.recipientUIDParsed)

    const db = admin.firestore()
    const userID = context.auth.uid
    const recipientUID = data.recipientUID
    const amount = data.amount
    // const currency = data.currency

    const transactionData = {
      from: userID,
      to: recipientUID,
      datetime: Math.round(Date.now()/1000),
      //currency: currency,
      amount: amount
    }

    // now we have all the input we need ^

    let userRef = db.collection("users").doc(userID)
    let recipientRef = db.collection("users").doc(recipientUID)

    var oldUserBalance = 0
    var oldRecipientBalance = 0

    // boolean flag to check the balances have been correctly fetched
    var balanceFail = false

    // get the user balance 
    await userRef.get().then(doc => {
      return oldUserBalance = doc.data().balance;
    })
    .catch(err => {
      balanceFail = true
      console.log('Error getting user balance', err);
    });

    // get the recipient balance
    await recipientRef.get().then(doc => {
      return oldRecipientBalance = doc.data().balance; 
    })
    .catch(err => {
      balanceFail = true
      console.log('Error getting recipient balance', err);
    });

    // if both balances have been correctly retrieved, trigger the transaction
    if (balanceFail !== true) {

      // runTransaction is a Firebase thing - designed for this kind of use case
      let transaction = db.runTransaction(t => {
        // return t.get(userRef)
        //   .then(doc => {
        
        // here's the magic
        if (amount <= oldUserBalance && amount > 0) {
              
          // P.S. the sendAmount > 0 should always pass since there will be validation elsewhere. However, suggest leaving it in as it doesn't hurt and if the FE validation ever breaks for whatever reason, allowing sendAmount < 0 would be a catastrophic security issue i.e. this is a useful failsafe
          
          let newUserBalance = oldUserBalance - amount
          let newRecipientBalance = oldRecipientBalance + amount

          // update both parties' balances
          t.update(userRef, {balance: newUserBalance});
          t.update(recipientRef, {balance: newRecipientBalance})
          
          // Add a new document with a generated id.
          return db.collection('transactions').add(transactionData)
        } else {
          return nil        
        }
      }).then(result => {
        // this transaction will only complete if both parties' balances are updated
        console.log('Transaction success!');
        return { text: "success" };
      }).catch(err => {
        console.log('Transaction failure:', err);
        return { text: "failure" };
      });
    } else {
      // TODO there was an error getting one of the balances - abort transaction and inform user
      console.log('one or more of the balances was not retrieved')
    }
  })

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
      console.log('Error getting userID', err);
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
    const fee = ceil(amount/100*1.8)

    // using the Firebase userID (supplied via 'context' of the request), get the data we need for the payin 
    await admin.firestore().collection('users').doc(userID).get().then(doc => {
      userData = doc.data();
      mangopayID = userData.mangopayID
      walletID = userData.defaultWalletID
      cardID = userData.defaultCardID

      billingAddress["AddressLine1"] = userData.defaultBillingAddress[line1]
      billingAddress["AddressLine2"] = userData.defaultBillingAddress[line2]
      billingAddress["City"] = userData.defaultBillingAddress[city]
      billingAddress["Region"] = userData.defaultBillingAddress[region]
      billingAddress["PostalCode"] = userData.defaultBillingAddress[postCode]
      billingAddress["Country"] = userData.defaultBillingAddress[country]

      culture = userData.culture
      return
    })
    .catch(err => {
      console.log('Error getting userID', err);
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
        "SecureMode": "DEFAULT",
        "StatementDescriptor": "WILDFIRE TOPUP",
        "Billing": {
          "Address": billingAddress
        },
        "Culture": culture
        }

    const payin = mpAPI.PayIns.create(payinData)

    return payin
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
    //   console.log('Error getting userID', err);
    // })

    // TODO add MangoPay Card Deactivation (useful code above)


    return cardsList = mpAPI.Users.getCards(mangopayID, JSON)

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