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

// When a user is created, register them with MangoPay and add an empty PaymentMethods collection
// exports.createNewMangopayCustomer = functions.region('europe-west1').firestore.document('users/{id}').onCreate(async (snap, context) => {
  
//   const data = snap.data()

//   var firstname = data.firstname
//   var lastname = data.lastname
//   var email = data.email
//   var birthday = data.dob
//   var nationality = data.nationality
//   var residence = data.residence

//   const customer = await mpAPI.Users.create({PersonType: 'NATURAL', FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email});

//   return admin.firestore().collection('users').doc(context.params.id).update({mangopayID: customer.Id});

// })

// When a user is created, register them with MangoPay and add an empty PaymentMethods collection
exports.createNewMangopayCustomerONCALL = functions.region('europe-west1').https.onCall( async (data, context) => {
  
  const userid = context.auth.uid

  await admin.firestore().collection('users').doc(userid).get().then(doc => {
    
    userData = doc.data();
   
    const firstname = data.firstname
    const lastname = data.lastname
    const email = data.email
    const birthday = data.dob
    const nationality = data.nationality
    const residence = data.residence
   
    return
  })
  .catch(err => {
    console.log('Error getting userID', err);
  });

  const customer = await mpAPI.Users.create({PersonType: 'NATURAL', FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email});

  return admin.firestore().collection('users').doc(context.params.id).update({mangopayID: customer.Id});

})

  // When user adds a new payment method, a) create a MangoPay wallet, b) create a Card Registration Object, and c) save the card token
  exports.createPaymentMethodHTTPS = functions.region('europe-west1').https.onCall( async (data, context) => {

    const userid = context.auth.uid

    var mangopayID = []
    var mangopayIDString = ''
    const walletName = data.text


    await admin.firestore().collection('users').doc(userid).get().then(doc => {
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

    const cardReg = await mpAPI.CardRegistrations.create({UserId: mangopayIDString, Currency: 'EUR', CardType: "CB_VISA_MASTERCARD"});

    // we need to add a Wallet to the user's Firestore record - this will store the card token(s) for repeat payments

    return admin.firestore().collection('users').doc(userid).collection('wallets').doc(wallet.Id).set({
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

    const userid = context.auth.uid

    var mangopayID = ''
    const rd = data.regData
    const cardRegID = String(data.cardRegID)

    // using the Firebase userid (supplied via 'context' of the request), get the mangopayID 
    await admin.firestore().collection('users').doc(userid).get().then(doc => {
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
    return admin.firestore().collection('users').doc(userid).update({
      card1_id: cardObject.CardId
    })
    .catch(err => {
      console.log('Error saving to database', err);
    })
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