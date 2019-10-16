//
//  FirebaseAuthManager.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 09/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth

class FirebaseAuthManager {
    
    func login(credential: AuthCredential, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signInAndRetrieveData(with: credential, completion: { (firebaseUser, error) in
            completionBlock(error == nil)
        })
    }
    
//    func createUser(email: String, password: String, completionBlock: @escaping (_ success: Bool) -> Void) {
//        Auth.auth().createUser(withEmail: email, password: password) {(authResult, error) in
//            if let user = authResult?.user {
//                print(user)
//                completionBlock(true)
//            } else {
//                completionBlock(true)
//            }
//        }
//    }
//
//    func signIn(email: String, pass: String, completionBlock: @escaping (_ success: Bool) -> Void) {
//        Auth.auth().signIn(withEmail: email, password: pass) { (result, error) in
//            if let error = error, let _ = AuthErrorCode(rawValue: error._code) {
//                completionBlock(false)
//            } else {
//                print(result)
//                completionBlock(true)
//            }
//        }
//    }
}
