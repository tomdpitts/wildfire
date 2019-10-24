//
//  Send2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 18/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import libPhoneNumber_iOS
import SwiftyJSON

class Send2ViewController: UIViewController {
    
    lazy var functions = Functions.functions(region:"europe-west1")


    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var confirmationTick: UIImageView!
    @IBOutlet weak var searchStatus: UILabel!
    
    let phoneUtil = NBPhoneNumberUtil()
    var contact: Contact?
    var transaction: Transaction?
    var sendAmount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmationTick.isHidden = true
        self.searchStatus.isHidden = true
        
        if let number = contact?.phoneNumber {
            if let name = contact?.givenName {
                isRegistered(phoneNumber: number, name: name)
            }
        }
        
        
        errorLabel.isHidden = true
        
        if let name = contact?.givenName {
            navigationItem.title = "To \(name)"
        } else {
            navigationItem.title = "Recipient"
        }
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        amountTextField.becomeFirstResponder()
        if let contact = contact {
            recipientLabel.text = contact.fullName
        }
    }
    
    func isRegistered(phoneNumber: String, name: String) {
        // to check whether the selected contact is already registered, we pass the number to Cloud Functions to search against database
        
        // call the function to check for a match
        functions.httpsCallable("isRegistered").call(["phone": phoneNumber]) { (result, error) in
            //                if let error = error as NSError? {
            //                    if error.domain == FunctionsErrorDomain {
            //                        let code = FunctionsErrorCode(rawValue: error.code)
            //                        let message = error.localizedDescription
            //                        let details = error.userInfo[FunctionsErrorDetailsKey]
            //                    }
            //                    // ...
            //                }
            
            let json = JSON(result?.data ?? "no data returned")
            
            if let uid = json["uid"].string {
                self.confirmationTick.isHidden = false
                self.searchStatus.text = "\(name) is registered"
                self.searchStatus.isHidden = false
                self.contact?.uid = uid
            } else {
                // searched for the number but no match found i.e. the contact isn't registered
                self.searchStatus.text = "Text \(name) a download link to collect their money"
                self.searchStatus.isHidden = false
            }
        }
    
    

        // the below is old code to check against the firestore database
//        if let phone = contact?.phoneNumber {
//
//            let phoneString = String(phone)
//
//            let phoneClean = phoneString.filter("0123456789".contains)
//
//            // Create a query against the collection.
//            let ref = Firestore.firestore().collection("users")
//            let query = ref.whereField("phone", isEqualTo: phoneClean)
//
//            query.getDocuments() { (querySnapshot, err) in
//                if let err = err {
//                    print("Error getting documents: \(err)")
//                } else {
//                    for document in querySnapshot!.documents {
//                        print("\(document.documentID) => \(document.data())")
//
//                    }
//                }
//            }
//        }
//        return
    }
    
    func validateAmount() -> Bool {
        if amountTextField.text == "" {
            errorLabel.text = "Please enter an amount to send \(String(describing: contact?.givenName))"
            errorLabel.isHidden = false
            return false
        } else {
            if let n = amountTextField.text {
                if let m = Int(n) {
                    self.sendAmount = m
                    return true
                } else {
                    // TODO error handling
                    errorLabel.text = "Please enter a valid number"
                    errorLabel.isHidden = false
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        let success = validateAmount()
        if success == true {
            errorLabel.isHidden = true
            performSegue(withIdentifier: "goToConfirm", sender: self)
        } else {
            return
        }
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
            
            let recipientUID = contact?.uid
            
           
            if let uid = recipientUID {
                vc.recipientUID = uid
                vc.sendAmount = sendAmount
            }
        }
    }
    
    
}
