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
import MessageUI

class Send2ViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    lazy var functions = Functions.functions(region: "europe-west1")


    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var confirmationTick: UIImageView!
    @IBOutlet weak var searchStatus: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    let phoneUtil = NBPhoneNumberUtil()
    var contact: Contact?
    
    var sendAmount = 0
    var isRegistered = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmationTick.isHidden = true
        self.sendButton.isEnabled = false
        
        
        if let number = contact?.phoneNumber {
            if let name = contact?.givenName {
                isRegistered(phoneNumber: number, name: name)
            }
        }
        
        
        errorLabel.isHidden = true
        
        if let name = contact?.fullName {
            navigationItem.title = "To \(name)"
        } else {
            navigationItem.title = "Recipient"
        }
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        amountTextField.becomeFirstResponder()
    }
    
    func isRegistered(phoneNumber: String, name: String) {
        // to check whether the selected contact is already registered, we pass the number to Cloud Functions to search against database
        
        // call the function to check for a match
        functions.httpsCallable("isRegistered").call(["phone": phoneNumber]) { (result, error) in
            if let error = error as NSError? {
                print(error)
//                if error.domain == FunctionsErrorDomain {
//                    let code = FunctionsErrorCode(rawValue: error.code)
//                    let message = error.localizedDescription
//                    let details = error.userInfo[FunctionsErrorDetailsKey]
//                }
//                // ...
            }
            
            let json = JSON(result?.data ?? "no data returned")
            
            if let uid = json["uid"].string {
                self.confirmationTick.isHidden = false
                self.searchStatus.text = "\(name) is registered"
                self.searchStatus.isHidden = false
                
                // check the recipient isn't the user themself! If they are, we should go back to the previous screen and display an error message
                
                if uid != Auth.auth().currentUser?.uid {
                    self.contact?.uid = uid
                    self.isRegistered = true
                } else {
                    self.showAlert(title: "Oops", message: "Please select a recipient that isn't yourself")
                }
                
            } else {
                // searched for the number but no match found i.e. the contact isn't registered
                self.searchStatus.text = "Text \(name) a download link to collect their money"
                self.searchStatus.isHidden = false
            }
            
            self.sendButton.isEnabled = true
        }
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
            if isRegistered == true {
                performSegue(withIdentifier: "goToConfirm", sender: self)
            } else {
                sendText()
            }
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
    
    func sendText() {
        
        let messageBody = "Hi \(self.contact?.givenName), I'd like to send you £\(self.sendAmount) with Wildfire - the payments app. Download the app here to collect it http://tiny.cc/bznffz"
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = messageBody
            
            let phone = contact?.phoneNumber
            controller.recipients = ([phone] as! [String])
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController!, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
        }))
        self.present(alert, animated: true)
    }
    
    
}
