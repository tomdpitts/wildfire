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
}
