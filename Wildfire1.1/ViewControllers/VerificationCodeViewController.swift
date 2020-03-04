//
//  VerificationCodeViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth

class VerificationCodeViewController: UIViewController {

    @IBOutlet weak var verificationField: UITextField!
    
    @IBOutlet weak var verifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Verify"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        Utilities.styleHollowButton(verifyButton)
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        
        let check = validateField()
        guard let code = verificationField.text else { return }
        
        if check == true {
            signInWithVerificationCode(code: code)
        } else { return }
    }
    
    func validateField() -> Bool {
        guard let code = verificationField.text else { return false }
        let numerical = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code))
        
        if code.count == 6 && numerical == true {
            return true
        }
        return false
    }
    
    func signInWithVerificationCode(code: String) {
        if let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code)
            
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                if let error = error {
                    // TODO error handling..
                    print(error)
                    return
                }
                
                // User is signed in
                
                // update credit cards and bank accounts list
                let appDelegate = AppDelegate()
                appDelegate.fetchPaymentMethodsListFromMangopay()
                appDelegate.fetchBankAccountsListFromMangopay()
                
                // check whether the user has completed signup flow
                if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
                    Utilities().checkForUserAccount()
                }
                
                // segue to main screens
                self.performSegue(withIdentifier: "goToMainMenu", sender: self)
            }
        }
    }
}
