//
//  DeleteAccountViewController.swift
//  Wildfire
//
//  Created by Tom Daniel on 19/05/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import LocalAuthentication
import FirebaseFunctions
import FirebaseAuth

class DeleteAccountViewController: UIViewController {
    
    var remainingCredit = false
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var remainingCreditText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButtonRED(confirmButton)
        
        if !remainingCredit {
            remainingCreditText.isHidden = true
        }
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        
        deleteAccount() { result in
            if result == true {
                self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
            }
            
        }
    }
    
    
    
    fileprivate func deleteAccount(completion: @escaping (Bool) -> Void) {
        self.authenticateUser() { result in
            if result == true {
                self.showSpinner(titleText: "Deleting Account", messageText: nil)
                
                self.functions.httpsCallable("deleteUser").call(["foo": "bar"]) { (result, error) in
                    
                    self.removeSpinnerWithCompletion {
                        
                        if error != nil {
                            self.universalShowAlert(title: "Something went wrong", message: "Your account was not deleted.", segue: nil, cancel: false)
                            completion(false)
                        } else {
                            
                            // might be a timing thing, but in testing, user was usually still signed in even after calling deleteUser
                            do {
                                try Auth.auth().signOut()
                            } catch {
                                // should be a limited downside if the signout fails..?
                            }

                            self.resetUserDefaults()

                            completion(true)
                        }
                    }
                }
            } else {
                
                // authentication failed, assume user changed their mind.
                self.universalShowAlert(title: "Authentication Failed", message: "Your account was not deleted.", segue: nil, cancel: false)
                
                completion(false)
                
            }
        }
    }
    
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = "Enter Passcode"
//        context.localizedCancelTitle = "Logout"
        
        context.touchIDAuthenticationAllowableReuseDuration = 5
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            let reason = "Please confirm you want to delete your Account"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [unowned self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Please try restarting the app.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            completion(false)
        }
    }
    
    func resetUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
    }

}
