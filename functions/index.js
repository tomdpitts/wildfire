// File to manage all Cloud Functions
// Only use Cloud Firestore! Not Realtime database, and watch out for the different methods required


// Dependancies
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const gcs = require('@google-cloud/storage');

admin.initializeApp(functions.config().firebase);

// // Cloud Functions Reference
// // https://firebase.google.com/docs/functions/write-firebase-functions

// Each function requires its own exports.customFunction

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

exports.cleanupUserData = functions.auth.user().onDelete((userRecord,context) => {
  const uid = userRecord.uid
  const doc = admin.firestore().doc('/users/' + uid)
  return doc.update({isDeleted: true})
})
