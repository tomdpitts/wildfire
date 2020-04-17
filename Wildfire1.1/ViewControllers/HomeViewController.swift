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
    
    var loggedInUser = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up video in the background
//        setUpVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if Auth.auth().currentUser?.uid != nil {
            self.loggedInUser = true
        } else {
            self.loggedInUser = false
        }
        
        // the logic here is that we only need to have TouchID/FaceID if the user is logged in - otherwise we let the user go ahead
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if loggedInUser == true {
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
