// File to manage all Cloud Functions
// Only use Cloud Firestore! Not Realtime database, and watch out for the different methods required


// Dependancies
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const gcs = require('@google-cloud/storage');
const mangopay = require('mangopay2-nodejs-sdk');

const api = new mangopay({
                       clientId: 'wildfirewallet',
                       clientApiKey: 'cwSQuWi9RCbnr5Fh5HktxevT9ch0pK3wWUn4t5rHJkCP1KSCiu',
                       // Set the right production API url. If testing, omit the property since it defaults to sandbox URL
                       // baseUrl: 'https://api.mangopay.com'
                       });

admin.initializeApp(functions.config().firebase);

// // Cloud Functions Reference
// // https://firebase.google.com/docs/functions/write-firebase-functions

// Each function requires its own exports.customFunction


  // When a user is created, register them with MangoPay and add an empty PaymentMethods collection
exports.createMangopayCustomer = functions.region('europe-west1').auth.user().onCreate(async (user) => {

  var firstname = ""
  var lastname = ""
  var email = ""
  var birthday = 1463496101
  var nationality = "GB"
  var residence = "FR"

  await admin.firestore().collection('users').doc(user.uid).get().then(doc => {
    userData = doc.data();
    firstname = userData.firstname;
    lastname = userData.lastname;
    email = userData.email;
    return
  })
  .catch(err => {
    console.log('Error getting document', err);
  });

  const customer = await api.Users.create({PersonType: "NATURAL", FirstName: firstname, LastName: lastname, Birthday: birthday, Nationality: nationality, CountryOfResidence: residence, Email: email});

  return admin.firestore().collection('users').doc(user.uid).update({mangopay_id: customer.Id});
  });

  // When user adds a new payment method, a) create a MangoPay wallet, b) create a Card Registration Object, and c) save the card token
  exports.createPaymentMethodHTTPS = functions.region('europe-west1').https.onCall( async (data, context) => {
    var mangopay_id = []
    const walletName = data.text

    await admin.firestore().collection('users').doc(user.uid).get().then(doc => {
      userData = doc.data();
      mangopay_id.push(userData.mangopay_id);
      return
    })
    .catch(err => {
      console.log('Error getting userID', err);
    });

    const wallet = await api.Wallets.create({Owners: mangopay_id, Description: walletName, Currency: "EUR"});

    return admin.firestore().collection('users').doc(user.uid).collection('wallets').doc({wallet_id: wallet.Id}).set({
      created: wallet.CreationDate,
      balance: wallet.Balance["Amount"],
      description: wallet.Description,
      currency: wallet.Currency
    })
    .catch(err => {
      console.log('Error saving to database', err);
    });

    // transaction history should be dealt with later and the .set() method should handle the collection creation without any need to build it in now
  });
//

//// Add a payment source (card) for a user by writing a stripe payment source token to Realtime database
//exports.addPaymentSource = functions.firestore.document('/stripe_customers/{userId}/tokens/{pushId}').onCreate(async (snap, context) => {
//   const source = snap.data();
//   const token = source.token;
//   if (source === null){
//   return null;
//   }
//
//   try {
//   const snapshot = await admin.firestore().collection('stripe_customers').doc(context.params.userId).get();
//   const customer =  snapshot.data().customer_id;
//   const response = await stripe.customers.createSource(customer, {source: token});
//   return admin.firestore().collection('stripe_customers').doc(context.params.userId).collection("sources").doc(response.fingerprint).set(response, {merge: true});
//   } catch (error) {
//   await snap.ref.set({'error':userFacingMessage(error)},{merge:true});
//   return reportError(error, {user: context.params.userId});
//   }
//   });
//
//// [START chargecustomer]
//// Charge the Stripe customer whenever an amount is written to the Realtime database
//exports.createStripeCharge = functions.firestore.document('stripe_customers/{userId}/charges/{id}').onCreate(async (snap, context) => {
//     const val = snap.data();
//     try {
//     // Look up the Stripe customer id written in createStripeCustomer
//     const snapshot = await admin.firestore().collection(`stripe_customers`).doc(context.params.userId).get()
//     const snapval = snapshot.data();
//     const customer = snapval.customer_id
//     // Create a charge using the pushId as the idempotency key
//     // protecting against double charges
//     const amount = val.amount;
//     const idempotencyKey = context.params.id;
//     const charge = {amount, currency, customer};
//     if (val.source !== null) {
//     charge.source = val.source;
//     }
//     const response = await stripe.charges.create(charge, {idempotency_key: idempotencyKey});
//     // If the result is successful, write it back to the database
//     return snap.ref.set(response, { merge: true });
//     } catch(error) {
//     // We want to capture errors and render them in a user-friendly way, while
//     // still logging an exception with StackDriver
//     console.log(error);
//     await snap.ref.set({error: userFacingMessage(error)}, { merge: true });
//     return reportError(error, {user: context.params.userId});
//     }
//     });
//    // [END chargecustomer]]




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

// exports.createUserAccount = functions.auth.user().onCreate((userRecord, context) => {
//
//     // the onCreate method pulls the userRecord which contains info on the newly created userRecord
//     const uid = userRecord.uid
//     const email = userRecord.email
//     const displayName = userRecord.displayName
//     const photoUrl = userRecord.photoUrl || 'https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png'
//     const balance = 0
//
//     // define the path and define what should be added to the database
//     const doc = admin.firestore().doc('/users/' + uid)
//     // question for future - should we be using .set() with a return to guarantee completion of async task? Seems to work ok for now
//     return doc.set({
//      photoUrl: photoUrl,
//      email: email,
//      balance: balance,
//      displayName: displayName
//     })
//
// })

// Since all users exist in the database as a kind of duplicate of the User list, when a user deletes their account, rather than delete the record we're just adding an isDeleted flag - if the user ever wants to return their data is still available
