const admin = require('firebase-admin');
const fetch = require('node-fetch');

module.exports = {
    // timestamp: function() {
    //   console.log('Current Time in Unix Timestamp: ' + Math.floor(Date.now() / 1000));
    // },
  
    /**
     * @param {string} eventType The next level below 'events' e.g. KYC_SUCCEEDED.
     * @param {string} newCollection Destination container label for the situation e.g. KYCWasNotValidated. This is probably the only argument you'll need to manually provide a name for as the others should already be defined. This argument essentially defines the type of error the eventRecord will be saved as.
     * @param {string} eventRecord The unique auto-assigned ID for the record.
     * @param {string} mangopayResourceID The mangopayID for the object we received a trigger for.
     * @param {boolean} saveToStrangerThings Generally, you should leave this as false. true = will be added to the special strangerThings log, reserved for evidence of potential malicious interference.
     * @param {string} errorLog This is set to Null by default. Use in cases where you're catching an error - the error will then be saved in the new eventRecord. 
     */

    moveEventRecordTo: function(eventType, newCollection, eventRecord, mangopayResourceID, saveToStrangerThings = false, errorLog = null) {
      let db = admin.firestore()
  
      // add the eventRecord to the log specified by 'collection' parameter
      db.collection('events').doc(eventType).collection(newCollection).doc(eventRecord).set({
        eventType: eventType,
        resourceID: mangopayResourceID,
        error: errorLog,
        timestamp: Math.round(Date.now()/1000)
      })
  
      // and delete it from the eventQueue
      db.collection('events').doc(eventType).collection('eventQueue').doc(eventRecord).delete()
  

      if (saveToStrangerThings === true) {
        // add the eventRecord to the strangerThings log
        db.collection('strangerThings').doc(eventType).collection(newCollection).doc(eventRecord).set({
            eventType: eventType,
            resourceID: mangopayResourceID,
            error: errorLog
        })
      }
    },

    callCloudFunction: async function(functionName, data) {
      let url = `https://europe-west1-wildfire-30fca.cloudfunctions.net/${functionName}`

      await fetch(url, {
          method: 'POST',
          headers: {
              'Content-Type': 'application/json',
          },
          body: JSON.stringify({ data }),
      })
    }
  }