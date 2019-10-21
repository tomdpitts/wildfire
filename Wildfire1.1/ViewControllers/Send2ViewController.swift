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
import libPhoneNumber_iOS

class Send2ViewController: UIViewController {


    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    let phoneUtil = NBPhoneNumberUtil()
    var contact: Contact?
    var transaction: Transaction?
    var sendAmount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let phone = contact?.phoneNumber
        

        
        if let c = contact?.phoneNumber {
            isRegistered(phoneNumber: c)
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
    
    func isRegistered(phoneNumber: String) {
        
        if let phone = contact?.phoneNumber {
            
            let phoneString = String(phone)

            let phoneClean = phoneString.filter("0123456789".contains)
            
            // Create a query against the collection.
            let ref = Firestore.firestore().collection("users")
            let query = ref.whereField("phone", isEqualTo: phoneClean)
            
            query.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                    }
                }
            }
        }
        return
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
