//
//  AccountViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseDatabase

class AccountViewController: UIViewController {
    
    @IBOutlet var accountBalance: UILabel!
    
    // This 'ref' property will hold a firebase database reference
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    // Declare variable to hold account balance
    var liveBalance: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the firebase reference
        ref = Database.database().reference()
        
        // set new reference to the accounts branch specifically
        let accountsRef = ref?.child("accounts")
        
        // set new reference to the specific user's account node
        let userRef = accountsRef?.child("1001")
        
        userRef?.observeSingleEvent(of: .childAdded, with: { (snapshot) in
            let balance = snapshot.value!
            print(balance)
            
            
            self.accountBalance.text = "\(String(describing: balance))"
            self.liveBalance = String(describing: balance)
            
        })
        
        // set up the listener to listen out for changes to user's account node
    databaseHandle = userRef?.observe(.childChanged, with: {(snapshot) -> Void in
        
        // self.accountBalance.text = "edited"
        
        let balance = snapshot.value!
        
        if balance != nil {
            self.accountBalance.text = "\(String(describing: balance))"
            self.liveBalance = String(describing: balance)
            
            print(self.liveBalance)
            
            
        }
        
        // print(balance!)
        //self.accountBalance.text = "\(balance ?? default error)"
    
        
        /*if balance != nil {
        
            self.accountBalance.text = "\(balance)"
         
         
        }*/
        
    })
        
        
    }
    
    @IBAction func goToLogin(_ sender: UIButton) {
        performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    
}


