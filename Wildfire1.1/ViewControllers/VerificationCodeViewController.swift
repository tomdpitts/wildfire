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
    
    @IBOutlet weak var verifyButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(verifyButton)
        
        errorLabel.isHidden = true
        
        verificationField.delegate = self
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        
        self.showSpinner(onView: self.view, titleText: nil, messageText: nil)
        
        let check = validateField()
        guard let code = verificationField.text else { return }
        
        if check == true {
            signInWithVerificationCode(code: code)
        } else {
            self.removeSpinner()
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
                
                // update credit cards and bank accounts list (user may be returning)
                let appDelegate = AppDelegate()
                appDelegate.listCardsFromMangopay() { () in }
                appDelegate.fetchBankAccountsListFromMangopay() {}
                
                // check whether the user has previously completed signup flow
                if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
                    Utilities.checkForUserAccount()
                }
                
                Utilities.getCurrentRegistrationToken()
                Utilities.getMangopayID()
                
                self.removeSpinner()
                
                print("will try to segue")
                // segue to welcome
                self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                
                print("tried..")
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
}
