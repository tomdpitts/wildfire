//
//  VerificationCodeViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseInstanceID
import FirebaseFirestore

class VerificationCodeViewController: UIViewController, UITextFieldDelegate {


    
    @IBOutlet weak var verificationField: UITextField!
    
    @IBOutlet weak var privacySwitch: UISwitch!
    
    @IBOutlet weak var termsSwitch: UISwitch!
    
    
    @IBOutlet weak var verifyButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(verifyButton)
        
        errorLabel.isHidden = true
        
        verificationField.delegate = self
        verificationField.becomeFirstResponder()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func swipeDownGesture(_ sender: Any) {
        // swipe down (and only down) hides keyboard
        self.view.endEditing(true)
    }
    @IBAction func verifyTapped(_ sender: Any) {
        
        let privacy = privacySwitch.isOn
        let terms = termsSwitch.isOn
        
        if privacy == false || terms == false {
            errorLabel.text = "Please accept both agreements"
            errorLabel.isHidden = false
            return
        }
        
        let check = validateField()
        guard let code = verificationField.text else { return }
        
        if check == true {
            signInWithVerificationCode(code: code)
        } else {
            return
        }
    }
    
    func validateField() -> Bool {
        guard let code = verificationField.text else { return false }
        let numerical = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code))
        
        if code.count == 6 && numerical == true {
            return true
        } else {
            self.errorLabel.text = "Code must be 6 numerical digits"
            self.errorLabel.isHidden = false
            return false
        }
        
    }
    
    func signInWithVerificationCode(code: String) {
        
        self.showSpinner(titleText: "Logging in", messageText: nil)
        if let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
            
                if error != nil {
                    self.removeSpinner()
                    self.errorLabel.text = "Code doesn't match for some reason. Please check it, or resubmit your phone number and try again."
                    self.errorLabel.isHidden = false
                    return
                }
                
                // User is signed in
                
                let userAccountExists = UserDefaults.standard.bool(forKey: "userAccountExists")
                
                
                // check whether the user has previously completed signup flow
                // if there's no record, check that before moving on as users with existing accounts need to be able to access their existing balance as soon as they log in (i.e. it's worth waiting)
                if userAccountExists != true {
                    Utilities.checkForUserAccountWithCompletion() {
                        
                        let appDelegate = AppDelegate()
                        appDelegate.listCardsFromMangopay() {}
                        appDelegate.fetchBankAccountsListFromMangopay() {}
                        
                        Utilities.getCurrentRegistrationToken()
                        Utilities.getMangopayID()
                        
                        
                        self.removeSpinner()
                        
                        // segue to welcome
                        self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                    }
                    
                    
                } else {
                    
                    // update credit cards and bank accounts list (user is returning)
                    let appDelegate = AppDelegate()
                    appDelegate.listCardsFromMangopay() {}
                    appDelegate.fetchBankAccountsListFromMangopay() {}
                    
                    Utilities.getCurrentRegistrationToken()
                    Utilities.getMangopayID()
                    
                    self.removeSpinner()
                    
                    
                    // segue to welcome
                    self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                }

                
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == verificationField {
            let allowedCharacters = CharacterSet(charactersIn:"0123456789")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
    
    @objc func DismissKeyboard(){
        //Causes the view to resign from the status of first responder.
        view.endEditing(true)
    }
}
