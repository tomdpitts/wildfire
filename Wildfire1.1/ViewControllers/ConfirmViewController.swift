//
//  ConfirmViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreImage
import CryptoSwift
import Firebase
import FirebaseFunctions


class ConfirmViewController: UIViewController {
    
    let db = Firestore.firestore()
    var handle: AuthStateDidChangeListenerHandle?
    let userUID = Auth.auth().currentUser?.uid
    lazy var functions = Functions.functions(region:"europe-west1")

    var decryptedString = ""
    var sendAmount = 0

    var recipientUID = ""
    var recipientName = ""
    
    // these variables are flags to determine logic triggered by the confirm button on the page
    var enoughCredit = false
    var existingPaymentMethod = false

    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var recipientImage: UIImageView!
    
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var dynamicLabel: UILabel!
    
    
    // TODO add a timeout (60s? 120s?)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        
        // disable confirm button until recipient details are fully loaded
        confirmButton.isEnabled = false
        
        // check whether the user has completed signup flow
        if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
            let utilities = Utilities()
            utilities.checkForUserAccount()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // TODO replace this logic with check for user doc in Firestore as proof of having created user account
//            if (Auth.auth().currentUser?.uid) == nil {
//                self.userAccountExists = false
//            }
            
        }
        
        // TODO this existing payment strategy doesn't quite add up - needs to be replaced with a flag (and have checkForExistingPaymentMethod() run in ViewDidAppear
        checkForExistingPaymentMethod()
        
        // display transaction amount front and centre
        amountLabel.text = "£" + String(self.sendAmount)
        
        // get the recipient's full name and profile pic
        setUpRecipientDetails(uid: recipientUID)
        
        // format the profile pic nicely (should this live elsewhere?)
        recipientImage.contentMode = .scaleAspectFill
        recipientImage.layer.cornerRadius = recipientImage.frame.size.height/2
        recipientImage.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // update the labels to explain current balance and what the user can expect to happen next
        // for reasons explained in the func itself, this should be called AFTER setUpRecipientDetails, as they both refer to class variable sendAmount
        getUserBalance()
    }
    
    func setUpElements() {

        // Style the elements

        Utilities.styleFilledButton(self.backButton)
        Utilities.styleFilledButton(self.confirmButton)
        
        recipientLabel.isHidden = true
        currentBalance.isHidden = true
        dynamicLabel.isHidden = true

    }
    
    func setUpRecipientDetails(uid: String) {
        
        var recipientFirstname = ""
        var recipientLastname = ""
        var recipientImageURL = URL(string: "bbc.com")
        
        let docRef = self.db.collection("users").document(uid)
        
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
//              let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                let userData = document.data()
                
                recipientFirstname = userData?["firstname"] as! String
                recipientLastname = userData?["lastname"] as! String
                if let url = URL(string: userData?["photoURL"] as! String) {
                    recipientImageURL = url
                }
                
                if let riurl = recipientImageURL {
                    self.recipientImage.load(url: riurl)
                }
                self.recipientLabel.text = "to \(recipientFirstname) \(recipientLastname)"
                self.recipientLabel.isHidden = false
                
                // important to update the class variable recipientName because at present, the getUserBalance function relies on it
                // TODO: replace this clunky solution
                self.recipientName = "\(recipientFirstname) \(recipientLastname)"
                
                self.confirmButton.isEnabled = true
            }
        }
    }
    
    func getUserBalance() {
        // check this func doesn't crash if the user hasn't made an account yet!
        let uid = Auth.auth().currentUser!.uid
        
        let docRef = self.db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // leaving this nifty bit in case you want to check the data that's being returned
//                let dataDescription = document.data().map(String.init(describing:)) ?? "data is nil"
//                print(dataDescription)
                let userData = document.data()
                
                let userBalance = userData?["balance"] as! Int
                self.currentBalance.text = "Your current balance is £\(String(userBalance))"
                let difference = userBalance - self.sendAmount
                
                // TODO: add logic to handle the minimum top up amount so users don't authenticate a card payment for very small amounts
                if difference < 0 {
                    // due to the complexities of dealing with closures and async stuff, have resorted to updating class variable 'recipientName' in another function (setUpRecipientDetails) and then referring to it here. This should probably be improved in future but for now, ensure this function is only called after the other..!
                    self.dynamicLabel.text = "Hit 'confirm' to add £\(difference*(-1)) and pay \(self.recipientName)"
                    self.enoughCredit = false
                } else {
                    self.dynamicLabel.text = "Your remaining balance will be £\(difference)"
                    self.enoughCredit = true
                }
                
                // show these two labels (initially hidden)
                self.currentBalance.isHidden = false
                self.dynamicLabel.isHidden = false
                
            } else {
                // didn't get that document..
                return
            }
        }
        
    }
    
    func checkForExistingPaymentMethod() {
        // TODO if user has payment details set up, set class variable existingPaymentMethod to true
        // for now it will update to true by default
        self.existingPaymentMethod = false
        
        return
    }
    
    // TODO: complete this func
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        let userAccountExists = UserDefaults.standard.bool(forKey: "userAccountExists")
        if userAccountExists == true {
            if enoughCredit == true {
                // initiate transaction
                // TODO add spinner
                // TODO add semaphore or something to wait for result before continuing, with timeout
                transact(recipientUID: self.recipientUID, amount: self.sendAmount)
                // TODO add result (success or failure)
                performSegue(withIdentifier: "showSuccessScreen", sender: self)
            } else {
                if existingPaymentMethod == true {
                    // initiate topup (ideally with ApplePay & touchID)
                    
                } else {
                    // bring up Modal to add card details (but return the user to the flow - don't force them to scan again!
                    // this will probably come up in testing, but might be nice to present as popover instead
                    performSegue(withIdentifier: "goToPaymentSetup", sender: self)
                }
            }
        } else {
            // the user hasn't set up their account yet so we need to a) explain that and b) take them to the sign up flow
            showAlert(title: "Set up your Account", message: "We just need a few details to let you make a secure payment")
        }
    }
    
    // this func now lives in Cloud Functions - allows for realtime updates if any security concerns should ever arise
    func transact(recipientUID: String, amount: Int) {
        
        functions.httpsCallable("transact").call(["recipientUID": recipientUID, "amount": amount], completion: { (result, error) in
            // TODO error handling!
            if let error = error as NSError? {
                print(error)
        //                                if error.domain == FunctionsErrorDomain {
        //                                    let code = FunctionsErrorCode(rawValue: error.code)
        //                                    let message = error.localizedDescription
        //                                    let details = error.userInfo[FunctionsErrorDetailsKey]
        //                                }
                // ...
            } else {
                print("no error here")
            }
        })
    }
    
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "goToLogin", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
