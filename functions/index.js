const functions = require('firebase-functions');
const admin = require('firebase-admin');
const gcs = require('@google-cloud/storage');

admin.initializeApp(functions.config().firebase);



// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions

exports.createUserAccount = functions.auth.user().onCreate((userRecord, context) => {

       const uid = userRecord.uid
       console.log(userRecord)

       const email = userRecord.email
       const photoUrl = userRecord.photoUrl || 'https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png'


       const doc = admin.firestore().doc('/2users/' + uid)
       return doc.set({
         photoUrl: photoUrl,
         email: email

       })

})

exports.cleanupUserData = functions.auth.user().onDelete((userRecord,context) => {
  const uid = userRecord.uid
  const doc = admin.firestore().doc('/2users/' + uid)
  return doc.update({isDeleted: true})
})


// exports.onFileChange = functions.storage.object().onFinalize(event => {
//       console.log(event);
//       return;
//  });
