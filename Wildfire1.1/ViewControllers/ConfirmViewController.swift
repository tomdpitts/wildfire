//
//  ConfirmViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreImage
import CryptoSwift
import Firebase


class ConfirmViewController: UIViewController {
    
    let db = Firestore.firestore()
    var handle: AuthStateDidChangeListenerHandle?
    let userUID = Auth.auth().currentUser?.uid

    
    var finalString2 = ""
    var decryptedString = ""
    var sendAmount = 0
    var transactionAmountFinal = 0
    let UIDLength = 28
    let multiplicationFactor = 7
    var recipientUIDParsed = ""
    var recipientName = ""
    
    // these two variables are flags to determine logic triggered by the confirm button on the page
    var loggedInUser = false
    var enoughCredit = false
    var existingPaymentMethod = false

    @IBOutlet weak var QROutput: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var recipientImage: UIImageView!
    
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var dynamicLabel: UILabel!
    
    
    // TODO add a timeout (60s? 120s?)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        setUpElements()
        recipientLabel.alpha = 0
        currentBalance.alpha = 0
        dynamicLabel.alpha = 0
        
        if (Auth.auth().currentUser?.uid) != nil {
            self.loggedInUser = true
        } else {
            self.loggedInUser = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if (Auth.auth().currentUser?.uid) != nil {
                self.loggedInUser = true
            } else {
                self.loggedInUser = false
            }

            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // TODO this existing payment strategy doesn't quite add up - needs to be replaced with a flag (and have checkForExistingPaymentMethod() run in ViewDidAppear
        checkForExistingPaymentMethod()
        //        // first decrypt the QR data
        //        decryptedString = decryptQRString(QRstring: finalString2)
        
        // then extract the UID (at time of writing, last 28 characters
        self.recipientUIDParsed = String(finalString2.suffix(UIDLength))
        
        // then extract the transaction amount i.e. how much the transaction is for. Be careful to allow for any number of digits - strip out the UID
        let transactionAmount = Int(finalString2.dropLast(UIDLength))
        
        // safely unwrap the number which has been converted to Int from a string, and divide the number by 7 (in the ReceiveViewController, we multiplied the amount requested by 7 before adding it to the string. Simply another level of security that makes it harder to reverse engineer the QR generation - then someone couldn't even guess that the transaction amount is encoded somewhere in the QR string
        if let transactionAmountReal = transactionAmount {
            transactionAmountFinal = transactionAmountReal/multiplicationFactor
        } else {
            print("houston we have a problem")
            // this obviously needs better error handling
        }
        // now we have, in transactionAmountFinal... the final amount
        sendAmount = Int(transactionAmountFinal)
        
        
        QROutput.text = recipientUIDParsed
        // display transaction amount front and centre
        amountLabel.text = "£" + String(sendAmount)
        
        // get the recipient's full name and profile pic
        setUpRecipientDetails(uid: recipientUIDParsed)
        
        // format the profile pic nicely (should this live elsewhere?)
        recipientImage.contentMode = .scaleAspectFill
        recipientImage.layer.cornerRadius = recipientImage.frame.size.height/2
        recipientImage.clipsToBounds = true
        
        // update the labels to explain current balance and what the user can expect to happen next
        // for reasons explained in the func itself, this should be called AFTER setUpRecipientDetails, as they both refer to class variable sendAmount
        getUserBalance()
        }
    
    // the encryption first concatenates the amount and the recipient's UID, then encrypts it with AES 128, then encodes the resulting data array into a Hex string which can easily be passed to the QR generator function
    // consequently, the decryption needs to unwind all of that in reverse order
    func decryptQRString(QRstring: String) -> String {
        
        let hexString = Array<UInt8>(hex: QRstring)
        
        // set up CryptoSwift object aes with the right key and initialization vector
        let aes = try? AES(key: "afiretobekindled", iv: "hdjajshdhxdgeehf")
        let aesData = try? aes?.decrypt(hexString)

        let decryptedString = String(bytes: aesData!, encoding: .utf8)
        
        return decryptedString ?? "decryption failed"
    }

    
//    func setUpElements() {
//
//        // Style the elements
//
//        Utilities.styleFilledButton(backButton)
//        Utilities.styleFilledButton(confirmButton)
//
//    }
    
    func setUpRecipientDetails(uid: String) {
        
        var recipientFirstname = ""
        var recipientLastname = ""
        var recipientImageURL = URL(string: "bbc.com")
        
        let docRef = self.db.collection("users").document(uid)
        
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
//              let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                let userData = document.data()
                
                recipientFirstname = userData?["firstname"] as! String
                recipientLastname = userData?["lastname"] as! String
                if let url = URL(string: userData?["photoURL"] as! String) {
                    recipientImageURL = url
                }
                
                if let riurl = recipientImageURL {
                    self.recipientImage.load(url: riurl)
                }
                self.recipientLabel.text = "to \(recipientFirstname) \(recipientLastname)"
                self.recipientLabel.alpha = 1
                
                // important to update the class variable recipientName because at present, the getUserBalance function relies on it
                // TODO: replace this clunky solution
                self.recipientName = "\(recipientFirstname) \(recipientLastname)"
            }
        }
    }
    
    func getUserBalance() {
        // check this func doesn't crash if the user hasn't made an account yet!
        let uid = Auth.auth().currentUser!.uid
        let docRef = self.db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // leaving this nifty bit in case you want to check the data that's being returned
//                let dataDescription = document.data().map(String.init(describing:)) ?? "data is nil"
//                print(dataDescription)
                let userData = document.data()
                
                let userBalance = userData?["balance"] as! Int
                self.currentBalance.text = "Your current balance is £\(String(userBalance))"
                let difference = userBalance - self.sendAmount
                
                // TODO: add logic to handle the minimum top up amount so users don't authenticate a card payment for very small amounts
                if difference < 0 {
                    // due to the complexities of dealing with closures and async stuff, have resorted to updating class variable 'recipientName' in another function (setUpRecipientDetails) and then referring to it here. This should probably be improved in future but for now, ensure this function is only called after the other..!
                    self.dynamicLabel.text = "Hit 'confirm' to add £\(difference*(-1)) and pay \(self.recipientName)"
                    self.enoughCredit = false
                } else {
                    self.dynamicLabel.text = "Your remaining balance will be £\(difference)"
                    self.enoughCredit = true
                }
                
                // show these two labels (initially hidden)
                self.currentBalance.alpha = 1
                self.dynamicLabel.alpha = 1
                
            }
        }
        
    }
    func checkForExistingPaymentMethod() {
        // TODO if user has paymnet details set up, set class variable existingPaymentMethod to true
        // for now it will update to true by default
        self.existingPaymentMethod = true
        return
    }
    
    // TODO: complete this func
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        if loggedInUser == true {
            if enoughCredit == true {
                // initiate transaction
                // Update one field, creating the document if it does not exist.
                transact()
                performSegue(withIdentifier: "showSuccessScreen", sender: self)
            } else {
                if existingPaymentMethod == true {
                    // initiate topup (ideally with ApplePay & touchID)
                    
                } else {
                    // bring up Modal to add card details (but return the user to the flow - don't force them to scan again!
                    // this will probably come up in testing, but might be nice to present as popover instead
                    performSegue(withIdentifier: "goToPaymentSetup", sender: self)
                }
            }
        } else {
            // TODO show alert to ask the user to log in (they may or may not have thought they were already logged in), provide some context and/or rationale
            performSegue(withIdentifier: "goToLogin", sender: self)
        }
    }
    
    
    func transact() {
        
        let recipientRef = self.db.collection("users").document(self.recipientUIDParsed)
        if let uid = self.userUID {
            let userRef = db.collection("users").document(uid)
        
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                
                // set up user (="payer") Firestore document/database info
                let userDoc: DocumentSnapshot
                do {
                    try userDoc = transaction.getDocument(userRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                // do the same for the recipient doc
                let recipientDoc: DocumentSnapshot
                do {
                    try recipientDoc = transaction.getDocument(recipientRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                // create reference to current ('old') balance of user
                guard let oldUserBalance = userDoc.data()?["balance"] as? Int else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(userDoc)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                
                // ditto for recipient
                guard let oldRecipientBalance = recipientDoc.data()?["balance"] as? Int else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(recipientDoc)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                
                // here's the magic
                if self.sendAmount <= oldUserBalance && self.sendAmount > 0 {
                    
                    // P.S. the sendAmount > 0 should always pass since there will be validation elsewhere. However, suggest leaving it in as it doesn't hurt and if the FE validation ever breaks for whatever reason, allowing sendAmount < 0 would be a catastrophic security issue i.e. a useful failsafe
                    
                    let newUserBalance = oldUserBalance - self.sendAmount
                    let newRecipientBalance = oldRecipientBalance + self.sendAmount
                    
                    transaction.updateData(["balance": newUserBalance], forDocument: userRef)
                    transaction.updateData(["balance": newRecipientBalance], forDocument: recipientRef)

                } else {
                    return nil
                }
                
                return nil
                
                
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    print("Transaction successfully committed!")
                }
            }
        }
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
