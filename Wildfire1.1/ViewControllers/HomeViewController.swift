//
//  WelcomeViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 26/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
//import AVKit
import LocalAuthentication
import FirebaseAuth
//import FBSDKLoginKit

class HomeViewController: UIViewController {
    
//    var loggedInUser = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // check that the view is currently on top of stack, otherwise it's behind a popup notification
        if self.view.window != nil {
            if Auth.auth().currentUser?.uid != nil {
                authenticateUser()
            } else {
                self.performSegue(withIdentifier: "goToPhoneVerification", sender: self)
            }
        }
    }
    
    // Work in Progress
    // this is called when a notification
    func notificationDismissed() {
        print("notificationDismissed() was called")
        if Auth.auth().currentUser?.uid != nil {
            authenticateUser()
        } else {
            self.performSegue(withIdentifier: "goToPhoneVerification", sender: self)
        }
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = "Enter Passcode"
//        context.localizedCancelTitle = "Logout"
        
        context.touchIDAuthenticationAllowableReuseDuration = 5
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            let reason = "Securely access your account"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [unowned self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        
                        self.performSegue(withIdentifier: "goToPay", sender: self)
                        
                    } else {
                        // just try again. Previously auth failure triggered signOut which is just a terrible UX and it happens more often than you might think
                        self.authenticateUser()
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Please try restarting the app.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @IBAction func progressToMainApp(_ sender: UIButton) {
        
        performSegue(withIdentifier: "goToPay", sender: self)
    }
    
    @IBAction func unwindToWelcome(_ unwindSegue: UIStoryboardSegue) {
        //        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }

}

//protocol DismissNotificationDelegate: class {
//    func notificationDismissed()
//}
