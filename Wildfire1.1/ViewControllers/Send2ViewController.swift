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

class Send2ViewController: UIViewController, MFMessageComposeViewControllerDelegate, UITextFieldDelegate {
    
    lazy var functions = Functions.functions(region: "europe-west1")


    @IBOutlet weak var headerImage: UIImageView!
    
    @IBOutlet weak var smsLabel: UILabel!
    @IBOutlet weak var amountStack: UIStackView!
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var confirmationTick: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var searchStatus: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    let phoneUtil = NBPhoneNumberUtil()
    var contact: Contact?
    
    var sendAmount: Float?
    var isRegistered = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // .medium for iOS 13 onwards, .gray is deprecated but older iOS versions don't have .medium
        if #available(iOS 13.0, *) {
            spinner.style = .medium
        } else {
            spinner.style = .gray
        }
        
        self.confirmationTick.isHidden = true
        self.sendButton.isEnabled = false
        
        
        if let number = contact?.phoneNumber {
            
            print(number)

            
            guard let name = contact?.givenName else { return }
            
            isRegistered(phoneNumber: number, name: name)
            
        }
        
        Utilities.styleHollowButton(sendButton)
        
        amountTextField.delegate = self
        amountTextField.becomeFirstResponder()
        
        errorLabel.isHidden = true
        smsLabel.isHidden = true
        
        if let name = contact?.fullName {
            navigationItem.title = "To \(name)"
        } else {
            navigationItem.title = "Recipient"
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        amountTextField.becomeFirstResponder()
        spinner.startAnimating()
    }
    
    @IBAction func amountChanged(_ sender: Any) {
        guard let amountString = amountTextField.text else { return }
        
        var workString: String = amountString
        
        // 1: ensure amount is between 0.50 and 50
        
        guard let amountFloat = Float(workString) else { return }
        
        var x = amountFloat
        
        if x > 40.00 {
            x = 40.00
            self.universalShowAlert(title: "Max amount £40", message: "At this time, Wildfire can only transact amounts up to £40. This limit will be raised soon.", segue: nil, cancel: false)
        }
        
        if x < 0.5 {
            x = 0.5
            self.universalShowAlert(title: "Min amount £0.50", message: "At this time, Wildfire can only transact amounts above £0.50", segue: nil, cancel: false)
        }
        
        // 2: round to nearest 0.50
        
        let y = (Float(Int((2*x) + 0.5)))/2
        
        if x != y {
            self.universalShowAlert(title: "Apologies", message: "Only amounts in 50p increments can be transacted e.g. £3, £3.50, £4 etc", segue: nil, cancel: false)
        }
        
        // 3: round to 2 decimal places
        
        let z = String(y)
        
        let numberOfDecimalDigits: Int
         
        if let dotIndex = z.firstIndex(of: ".") {
             // prevent more than 2 digits after the decimal
             numberOfDecimalDigits = z.distance(from: dotIndex, to: z.endIndex) - 1
             
             if numberOfDecimalDigits == 1 {
                 let replacementString = z + "0"
                 workString = replacementString
                 
             } else if numberOfDecimalDigits == 0 {
                 let replacementString = String(z.dropLast())
                 workString = replacementString
             }
        }
        
        amountTextField.text = workString
    }

    func isRegistered(phoneNumber: String, name: String) {
        // to check whether the selected contact is already registered, we pass the number to Cloud Functions to search against database
        
        // call the function to check for a match
        functions.httpsCallable("isRegistered").call(["phone": phoneNumber]) { (result, error) in
            self.spinner.isHidden = true
            self.spinner.stopAnimating()
                        
            if let error = error as NSError? {
                
                print(error)
                self.headerImage.image = UIImage(named: "icons8-sms-100")
                self.searchStatus.text = "\(name) doesn't appear to be registered"
                self.smsLabel.text = "Text a download link to get them up and running"
                self.smsLabel.isHidden = false
                self.sendButton.setTitle("Send SMS", for: .normal)
                
            }
            
            if let recipientID = result?.data as? String {
                
                self.confirmationTick.isHidden = false
                self.searchStatus.text = "\(name) is registered"
                
                // check the recipient isn't the user themself! If they are, we should go back to the previous screen and display an error message
                
                if recipientID != Auth.auth().currentUser?.uid {
                    self.contact?.uid = recipientID
                    self.isRegistered = true
                    
                    self.headerImage.image = UIImage(named: "icons8-paper-plane-100 (2)")
                } else {
                    self.showAlert(title: "Oops", message: "Please select a recipient that doesn't have the same phone number as you")
                }
                
            } else {
                // searched for the number but no match found i.e. the contact isn't registered
                self.headerImage.image = UIImage(named: "icons8-sms-100")
                self.searchStatus.text = "\(name) doesn't appear to be registered"
                self.smsLabel.text = "Text a download link to get them up and running!"
                self.smsLabel.isHidden = false
                self.sendButton.setTitle("Send SMS", for: .normal)
            }
            
            self.sendButton.isEnabled = true
        }
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        self.view.endEditing(true)
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
    
    func validateAmount() -> Bool {
        if let text = amountTextField.text {
            if text == "" {
                errorLabel.text = "Please enter an amount to send \(String(describing: contact?.givenName))"
                errorLabel.isHidden = false
                return false
            } else {
                if let m = Float(text) {
                    self.sendAmount = m
                    return true
                } else {
                    errorLabel.text = "Please enter a valid number"
                    errorLabel.isHidden = false
                    return false
                }
            }
        } else {
            return false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
            
            let recipientUID = contact?.uid
            
           
            if let uid = recipientUID {
                vc.recipientUID = uid
                guard let amount = sendAmount else { return }
                vc.sendAmount = Int(amount * Float(100))
            }
        }
    }
    
    func sendText() {
        
        var contactName: String?
        var messageBody: String?
        
        if let n = self.contact {
            contactName = n.givenName
        }
        
        if let amount = amountTextField.text {
            if let name = contactName {
                messageBody = "Hi \(name), I'd like to send you £\(amount) with Wildfire - the payments app. Download the app here to collect it http://wildfire-30fca.web.app"
            } else {
                messageBody = "Hi, I'd like to send you £\(amount) with Wildfire - the payments app. Download the app here to collect it http://wildfire-30fca.web.app"
            }
        } else {
            messageBody = "Hi, I'd like to pay you with Wildfire - the payments app. Download the app here to collect it http://wildfire-30fca.web.app"
        }
        
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = messageBody
            
            let phone = contact?.phoneNumber
            controller.recipients = ([phone] as! [String])
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    // MFMessageComposeViewController used to be force unwrapped i.e. MFMessageComposeViewController! - removed the ! on Xcode's advice, if this bugs out then consider putting it back in
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            return true
        }

        let newText = oldText.replacingCharacters(in: r, with: string)
        let isNumeric = newText.isEmpty || (Double(newText) != nil)
        let numberOfDots = newText.components(separatedBy: ".").count - 1

        let numberOfDecimalDigits: Int
        if let dotIndex = newText.firstIndex(of: ".") {
            // prevent more than 2 digits after the decimal
            numberOfDecimalDigits = newText.distance(from: dotIndex, to: newText.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }

        return isNumeric && numberOfDots <= 1 && numberOfDecimalDigits <= 2
    }
    
    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
        }))
        self.present(alert, animated: true)
    }
    
    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
        //        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}
