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

class PhoneViewController: UIViewController {
    
    var global: GlobalVariables!
    
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var verifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Confirm mobile number"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        triggerPhoneCheck()
    }
    
    
    func triggerPhoneCheck() {
        guard let phoneNumber = phoneField.text else { return }
        
//        if phoneNumber.count < 11 || phoneNumber.count > 12 {
//            // TODO return error "please enter 11 digit number"..
//            print("please enter 11 digit number")
//            return
//        }
        
        let phoneUtil = NBPhoneNumberUtil()
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let err = error {
                print(err)
                //                self.showMessagePrompt(error.localizedDescription)
                return
            }
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            // Next step: Sign in using the verificationID and the code sent to the user
            
            self.performSegue(withIdentifier: "goToVerify", sender: self)
        }
    }
}
