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
import FBSDKLoginKit

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
            self.performSegue(withIdentifier: "goToPay", sender: self)
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
                        
                        do {
                            try Auth.auth().signOut()
                        } catch let err {
                            print(err)
                        }
                        
                        let ac = UIAlertController(title: "Continue", message: "You can log in again in the 'Account' Tab", preferredStyle: .alert)
                        
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in self.performSegue(withIdentifier: "goToPay", sender: self)}
                        ))
                        self.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @IBAction func progressToMainApp(_ sender: UIButton) {
        
        performSegue(withIdentifier: "goToPay", sender: self)
    }

}
