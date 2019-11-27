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

exports.addZeroBalanceOnCreation = functions.firestore
  .document('users/{userId}')
  .onCreate((snap, context) => {
    // get a ref to the doc
    const docRef = context.params.userId

    // add a field called 'balance' and set it to 0
    // this func is only called onCreate i.e. the very first time a user logs in with this phone number
    return admin.firestore().collection('users').doc(docRef).update({balance: 0})
  });

exports.addTransactionsToUsers = functions.firestore
  .document('transactions/{transactionID}')
  .onCreate((snap, context) => {

    const transactionID = context.params.transactionID
    
    // Get an object representing the document
    // e.g. {'name': 'Marie', 'age': 66}
    const data = snap.data();

    // get the payer and recipient user IDs
    const payerID = data.from;
    const recipientID = data.to;

    // get a ref to the payer and recipient user docs
    const payerDocRef = admin.firestore().collection('users').document(payerID);
    const recipientDocRef = admin.firestore().collection('users').document(recipientID);

    // pull the transaction Data to be added to both the payer and recipient transaction subcollections
    const transactionData = {
      from: data.from,
      to: data.to,
      datetime: data.datetime,
      //currency: data.currency,
      amount: data.amount
    };

    // within the 'receipts' subcollection for the payer and recipient user docs, we add a doc with the transactionID
    let newPayerTransaction = payerDocRef.collection('receipts').doc(transactionID).set(transactionData);
    let newRecipientTransaction = recipientDocRef.collection('receipts').doc(transactionID).set(transactionData)
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

    // create Wallet and CardRegistration objects

    const wallet = await mpAPI.Wallets.create({Owners: mangopayID, Description: walletName, Currency: 'EUR'});

    const cardReg = await mpAPI.CardRegistrations.create({userID: mangopayIDString, Currency: 'EUR', CardType: "CB_VISA_MASTERCARD"});

    // we need to add a Wallet to the user's Firestore record - this will store the card token(s) for repeat payments

    return admin.firestore().collection('users').doc(userID).collection('wallets').doc(wallet.Id).set({
      created: wallet.CreationDate,
      balance: wallet.Balance['Amount'],
      description: wallet.Description,
      currency: wallet.Currency,
      // this last line is new
      card_registration_id: cardReg.Id
    })
    .catch(err => {
      console.log('Error saving to database', err);
    })
    // this function deals with steps 1-4 outlined here: https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
    // we 1) created a wallet using the mangopayID stored in Firestore, then 2) created a CardRegistration object, and now need to return the CardRegistration object to the client as per the docs
    .then(() => {
      // 
      return cardReg;
    })
    // transaction history should be dealt with later and the .set() method should handle the collection creation without any need to build it in now
  });

  exports.addCardRegistration = functions.region('europe-west1').https.onCall( async (data, context) => {

    const userID = context.auth.uid

    var mangopayID = ''
    const rd = data.regData
    const cardRegID = String(data.cardRegID)

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
    // step 5: Update a Card Registration
    const cardObject = await mpAPI.CardRegistrations.update({RegistrationData: rd, Id: cardRegID})

    // and save the important part of the response - the cardId - to the Firestore (at 'user' level, not in 'wallets')
    return admin.firestore().collection('users').doc(userID).update({
      card1_id: cardObject.CardId
    })
    .catch(err => {
      console.log('Error saving to database', err);
    })
  })

  // transact function needs to also log the transaction in Firestore
  exports.transact = functions.region('europe-west1').https.onCall( async (data, context) => {
    //        let recipientRef = self.db.collection("users").document(self.recipientUIDParsed)

    const db = admin.firestore()
    const userID = context.auth.uid
    const recipientUID = data.recipientUID
    const amount = data.amount
    // const currency = data.currency

    const transactionData = {
      from: userID,
      to: recipientUID,
      datetime: Date.now,
      //currency: currency,
      amount: amount
    }

    // now we have all the input we need ^

    const userRef = db.collection("users").document(userID)
    const recipientRef = db.collection("users").document(recipientUID)

    var oldUserBalance = 0
    var oldRecipientBalance = 0

    // boolean flag to check the balances have been correctly fetched
    var balanceFail = false

    // get the user balance 
    await userRef.get().then(doc => {
      oldUserBalance = doc.data().balance;
      return
    })
    .catch(err => {
      balanceFail = true
      console.log('Error getting user balance', err);
    });

    // get the recipient balance
    await recipientRef.get().then(doc => {
      oldRecipientBalance = doc.data().balance; 
      return
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
          let addDoc = db.collection('transactions').add(transactionData)

        } else {
            return nil
        }
        return nil
      }).then(result => {
        // this transaction will only complete if both parties' balances are updated
        console.log('Transaction success!');
        return result
      }).catch(err => {
        console.log('Transaction failure:', err);
        return result
      });
    } else {
      // TODO there was an error getting one of the balances - abort transaction and inform user
    }
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
