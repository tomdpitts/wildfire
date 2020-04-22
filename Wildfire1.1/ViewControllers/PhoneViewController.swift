//
//  PhoneViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import libPhoneNumber_iOS

class PhoneViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // we don't want the user to go back to the welcome screen
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
//        self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false;
        
        Utilities.styleHollowButton(verifyButton)
        
        errorLabel.isHidden = true
        
        phoneField.delegate = self
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        triggerPhoneCheck()
    }
    
    
    func triggerPhoneCheck() {
        guard let phoneNumber = phoneField.text else { return }
        
        if phoneNumber.count < 11 || phoneNumber.prefix(1) != "+" {
            self.removeSpinner()
            // TODO return error "please enter 11 digit number"..
            errorLabel.text = "Please enter a valid 11 or 12 digit phone number, beginning with international dialling code e.g. '+44'"
            errorLabel.isHidden = false
            return
        }
        
//        let phoneUtil = NBPhoneNumberUtil()
        
        self.showSpinner(titleText: nil, messageText: nil)
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            self.removeSpinner()
            if error != nil {
                self.errorLabel.text = "Could not validate phone number - please check it begins with the country code (e.g. +44)"
                self.errorLabel.isHidden = false
                
                //                self.showMessagePrompt(error.localizedDescription)
                return
            }
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            // Next step: Sign in using the verificationID and the code sent to the user
            
            self.performSegue(withIdentifier: "goToVerify", sender: self)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == phoneField {
            let allowedCharacters = CharacterSet(charactersIn:"+0123456789")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
