//
//  AccountViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AccountViewController: UIViewController {
    
    @IBOutlet var accountBalance: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    
    @IBOutlet weak var goToLoginButton: UIButton!
    @IBOutlet weak var addPaymentMethodButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    
    
    
    // This 'ref' property will hold a firebase database reference
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    // Declare variable to hold account balance
    var liveBalance: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleFilledButton(goToLoginButton)
        Utilities.styleFilledButton(addPaymentMethodButton)
        Utilities.styleFilledButton(signOutButton)
        
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
            
        }
        
        // print(balance!)
        //self.accountBalance.text = "\(balance ?? default error)"
    
        
        /*if balance != nil {
        
            self.accountBalance.text = "\(balance)"
         
         
        }*/
        
    })
        
        
    }
    
    @IBAction func refreshUID(_ sender: Any) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.uidLabel.text = "Not logged in"
            return
        }
        self.uidLabel.text = uid
    }
    
    
    @IBAction func goToLogin(_ sender: UIButton) {
        performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    
    // this unwind segue is deliberately generic! Allows the Back button on PaymentSetupVC to unwind to the appropriate VC depending on where it came from
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    // This unwind segue exists independently to the above to allow a specific unwind call e.g. in LoginVC
    @IBAction func unwindToAccountView(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        
        // Declare Alert message
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.signOut()
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)

        
        
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let err {
            print(err)
        }
    }
}


