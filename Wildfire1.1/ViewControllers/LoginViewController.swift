//
//  LoginViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseUI


class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
//    var actionCodeSettings = ActionCodeSettings()
//    actionCodeSettings.url = URL(string: "https://example.appspot.com")
//    actionCodeSettings.handleCodeInApp = true
//    actionCodeSettings.setAndroidPackageName("com.firebase.example", installIfNotAvailable: false, minimumVersion: "12")
//
//    let provider = FUIEmailAuth.initAuthAuthUI(FUIAuth.defaultAuthUI(), signInMethod: FIREmailLinkAuthSignInMethod, forceSameDevice: false, allowNewEmailAccounts: true, actionCodeSetting: actionCodeSettings)


    @IBAction func loginButtonTapped(_ sender: UIButton) {

        // get the default auth UI object
        let authUI = FUIAuth.defaultAuthUI()
        
        guard authUI != nil else {
            // Log the error
            return
        }
        // Set ourselves as the delegate
        authUI?.delegate = self
        
        // get a reference to the auth UI view controller
        let authViewController = authUI!.authViewController()
        
        // Show it
        present(authViewController, animated: true, completion: nil)
    }
    
}

extension LoginViewController: FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        
        // check for errors
        guard error == nil else {
            // log error
            return
        }
        
        // authDataResult?.user.uid
        performSegue(withIdentifier: "goHome", sender: self)
    }
}
