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
import LocalAuthentication
import Kingfisher

class ConfirmViewController: UIViewController {
    // TODO this VC is not super well structured - could do with some refactoring in future
    
    let db = Firestore.firestore()
    var handle: AuthStateDidChangeListenerHandle?
    let userUID = Auth.auth().currentUser?.uid
    lazy var functions = Functions.functions(region:"europe-west1")

    var decryptedString = ""
    var sendAmount = 0
    
    var topupAmount: Int?

    var recipientUID = ""
    var recipientName = ""
    
    // these variables are flags to determine logic triggered by the confirm button on the page
    var enoughCredit = false
    var existingPaymentMethod = false
    var shouldReloadView = false
    
    var confirmedTransaction: Transaction?
    
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
        
        // check whether the user has completed signup flow
        if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
            Utilities.checkForUserAccount()
        }
        
        // get the recipient's full name and profile pic
        setUpRecipientDetails(recipientUID)
        
        checkForExistingPaymentMethod()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // this is for the scenario in which a user has just added a card while in the payment view. N.B. this is (probably) going to happen max 1 time per user, but it's extremely important this flow is as seamless as possible since users are likely to judge the usefulness of the app on this experience i.e. it's make or break
        if shouldReloadView == true {
            // check whether the user has completed signup flow
            if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
                
                Utilities.checkForUserAccount()
            }
        }
        
        self.showSpinner(onView: self.view, text: nil)
        
        
    }
    

//        // update the labels to explain current balance and what the user can expect to happen next
//        // for reasons explained in the func itself, this should be called AFTER setUpRecipientDetails, as they both refer to class variable sendAmount
//        getUserBalance()
//    }
    
    func setUpElements() {

        // Style the elements
        Utilities.styleHollowButtonRED(self.backButton)
        Utilities.styleFilledButton(self.confirmButton)
        
        
        currentBalance.isHidden = true
        dynamicLabel.isHidden = true
        
        // disable confirm button until recipient details are fully loaded
        confirmButton.isEnabled = false

        // format the profile pic image view nicely
//        recipientImage.contentMode = .scaleAspectFill
        
        recipientImage.clipsToBounds = true
        recipientImage.layer.cornerRadius = recipientImage.bounds.height/2
        
        let sendAmountFloat = Float(sendAmount)/100
        // TODO update with appropriate currency
        // display transaction amount front and centre
        amountLabel.text = "£" + String(format: "%.2f", sendAmountFloat)
    }
    
    func setUpRecipientDetails(_ uid: String) {
        
        loadRecipientProfilePicView(uid)
        
        let docRef = self.db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
//              let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                let userData = document.data()
                
                let recipientFirstname = userData?["firstname"] as! String
                let recipientLastname = userData?["lastname"] as! String
            
                
                
                self.recipientLabel.text = "to \(recipientFirstname) \(recipientLastname)"
                
                // important to update the class variable recipientName because at present, the getUserBalance function relies on it
                // TODO: replace this clunky solution?
                self.recipientName = "\(recipientFirstname) \(recipientLastname)"
                
                // this func can be called now that the recipient data is available
                self.getUserBalance()
            }
        }
    }
    
    func getUserBalance() {
        // TODO double check this func doesn't crash if the user hasn't made an account yet!
        let uid = Auth.auth().currentUser!.uid
        
        let docRef = self.db.collection("users").document(uid)
        // this balance should be up to date as the 
        docRef.getDocument { (document, error) in
            
            if error != nil {
                self.showAlert(title: "Hmm..", message: "Apologies - we're having connectivity issues. Please try again.", segue: nil, cancel: false)
            }
            if let document = document, document.exists {
                
                let userData = document.data()
                
                let userBalance = userData?["balance"] as! Int
                
                // N.B. all database amounts are in cents i.e. £43.50 is '4350'
                let userBalanceFloat = Float(userBalance)/100
                self.currentBalance.text = "Your current balance is £\(String(format: "%.2f", (userBalanceFloat)))"
                let difference = userBalance - self.sendAmount
                
                // TODO: add logic to handle the minimum top up amount so users don't authenticate a card payment for very small amounts
                if difference < 0 {
                    // we'll need this amount available for transact function to access if user wants to top up
                    self.topupAmount = difference*(-1)
                    
                    // due to the complexities of dealing with closures and async stuff, have resorted to updating class variable 'recipientName' in another function (setUpRecipientDetails) and then referring to it here. This should probably be improved in future but for now, ensure this function is only called after the other..!
                    let differenceString = String(format: "%.2f", Float(difference*(-1))/100)
                    let totalCharge = String(format: "%.2f", Float(difference*(-1) + 20)/100)
                    self.dynamicLabel.text = "Tap 'Confirm' to top up £\(differenceString) and pay \(self.recipientName). Card charge is 20p so you'll be charged £\(totalCharge)"
                    self.enoughCredit = false
                } else {
                    
                    let diffFloat = String(format: "%.2f", Float(difference)/100)
                    self.dynamicLabel.text = "Your remaining balance will be £\(diffFloat)"
                    self.enoughCredit = true
                }
                
                // show these two labels (initially hidden)
                self.currentBalance.isHidden = false
                self.dynamicLabel.isHidden = false
                
                self.confirmButton.isEnabled = true
                
                self.removeSpinner()
                
            } else {
                // user hasn't added account info yet
                //
                
                self.dynamicLabel.text = "Please provide some quick details to complete payment"
                
                self.confirmButton.setTitle("Continue", for: .normal)
                
                self.dynamicLabel.isHidden = false
                self.confirmButton.isEnabled = true
                
                self.removeSpinner()
                
                return
            }
        }
        
    }
    
    func checkForExistingPaymentMethod() {
        
        let defaults = UserDefaults.standard
        
        let count = defaults.integer(forKey: "numberOfCards")
        
        if count > 0 {
            self.existingPaymentMethod = true
        } else {
            self.existingPaymentMethod = false
        }
        
        
        return
    }
    
    // TODO: complete this func
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        
        let userAccountExists = UserDefaults.standard.bool(forKey: "userAccountExists")
        if userAccountExists == true {
            
            
            
            // notice user doesn't strictly need to add card details if they already have sufficient credit to complete payment - this is intentional
            if enoughCredit == true {
                self.showSpinner(onView: self.view, text: nil)
                
                // initiate transaction
                // TODO add spinner
                // TODO add semaphore or something to wait for result before continuing, with timeout
                transact(recipientUID: self.recipientUID, amount: self.sendAmount, topup: false, topupAmount: nil) { result in
                    
                    self.removeSpinner()
                    
                    let trunc = result.prefix(7)
                    if trunc == "success" {
                        
                        self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                    } else {
                        
                        self.showAlert(title: "Oops!", message: result, segue: nil, cancel: false)
                    }
                    
//                    self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                }
            } else {
                if existingPaymentMethod == true {
                    
                    self.showSpinner(onView: self.view, text: nil)
                    
                    // initiate topup (ideally with ApplePay & touchID)
                    transact(recipientUID: self.recipientUID, amount: self.sendAmount, topup: true, topupAmount: self.topupAmount) { result in
                        
                        self.removeSpinner()
                        
                        let trunc = result.prefix(7)
                        if trunc == "success" {
                            
                            // TODO get updated balance

                            self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                        } else {
                            
                            self.showAlert(title: "Oops!", message: result, segue: nil, cancel: false)
                        }
                    }
                } else {
                    // bring up Modal to add card details (but return the user to the flow - don't force them to scan again!
                    // this will probably come up in testing, but might be nice to present as popover instead
                    showAlert(title: "Add card details", message: "We just need a few details to let you make a secure payment", segue: "goToAddCard", cancel: true)
                }
            }
        } else {
            // the user hasn't set up their account yet so we need to a) explain that and b) take them to the sign up flow
            showAlert(title: "Set up your Account", message: "We just need a few details to let you make a secure payment", segue: "goToSignup", cancel: true)
        }
    }
    
    // the meat and bones of what happens in a transaction now lives in Cloud Functions - allows for realtime updates if any urgent concerns should ever arise
    func transact(recipientUID: String, amount: Int, topup: Bool, topupAmount: Int?, completion: @escaping (String) -> Void) {
        
        // cloud functions don't like integers..
//        let amountString = String(amount)
//        print(recipientUID)
//        print(amountString)
        
        
        // for sake of readibility, we first divide into two cases: 1) user wants to topup and transact, 2) user just wants to transact - they already have sufficient credit.
        if topup == true {
            authenticatePayment() { authenticated in
                if authenticated == true {
                    // N.B. topupAmount must be passed if topup == true. Guarding so that this breaks if this condition isn't met.
                    guard let tpa = topupAmount else { return }
                                        
                    self.functions.httpsCallable("createPayin").call(["amount": tpa, "currency": "EUR"]) { (result, error) in
                        if error != nil {
                            // TODO
                            
                            completion("We couldn't top up your account. Please try again.")
                        } else {
                            
                            self.functions.httpsCallable("getCurrentBalance").call(["foo": "bar"]) { (result, error) in
                                
                                if error != nil {
                                    completion("We topped up your account but failed to complete the transaction. Please try again.")
                                } else {
                                    
                                    self.functions.httpsCallable("transact").call(["recipientUID": recipientUID, "amount": amount, "currency": "EUR"]) { (result, error) in
                                        // TODO error handling!
                                        if error != nil {
        //                                    self.showAuthenticationError(title: "Oops!", message: "We topped up your account but couldn't complete the transaction. Please try again.")
                                            completion("We topped up your account but couldn't complete the transaction. Please try again.")
                                            // in this scenario, the top up went through and only the transaction failed. This means we need to refresh certain parts of the view, and temporarily disable the confirm button until that's done
                                            self.confirmButton.isEnabled = false
                                            self.getUserBalance()
                                            
                                        } else {
                                            
                                            if let transactionData = result?.data as? [String: Any] {
                                                let amount = transactionData["amount"] as! Int
                                                let currency = transactionData["currency"] as! String
                                                
                                                let datetimeUNIX = transactionData["datetime"] as! Int
                                                let datetime = Date(timeIntervalSince1970: TimeInterval(datetimeUNIX))
                                                
                                                let payerID = transactionData["payerID"] as! String
                                                let recipientID = transactionData["recipientID"] as! String
                                                let payerName = transactionData["payerName"] as! String
                                                let recipientName = transactionData["recipientName"] as! String
                                                let userIsPayer = transactionData["userIsPayer"] as! Bool
                                                
                                                
                                                self.confirmedTransaction = Transaction(amount: amount, currency: currency, datetime: datetime, payerID: payerID, recipientID: recipientID, payerName: payerName, recipientName: recipientName, userIsPayer: userIsPayer)
                                            }
                                            
                                            completion("success (topped up)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
//                    self.showAuthenticationError(title: "Oops", message: "Apologies - we couldn't authenticate this transaction. Please try again. ")
                    completion("Apologies - we couldn't authenticate this transaction. Please try again. ")
                }
            }
        } else {
            authenticatePayment() { authenticated in
                if authenticated == true {
                    
                    
                    self.functions.httpsCallable("transact").call(["recipientUID": recipientUID,  "amount": amount, "currency": "EUR"]) { (result, error) in
                        // TODO error handling!
                        if error != nil {
                            completion("Error in transaction function")
                            print(error)
                    //                                if error.domain == FunctionsErrorDomain {
                    //                                    let code = FunctionsErrorCode(rawValue: error.code)
                    //                                    let message = error.localizedDescription
                    //                                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    //                                }
                            // ...
                        } else {
                            
                            if let transactionData = result?.data as? [String: Any] {
                                let amount = transactionData["amount"] as! Int
                                let currency = transactionData["currency"] as! String
                                
                                let datetimeUNIX = transactionData["datetime"] as! Int
                                let datetime = Date(timeIntervalSince1970: TimeInterval(datetimeUNIX))
                                
                                let payerID = transactionData["payerID"] as! String
                                let recipientID = transactionData["recipientID"] as! String
                                let payerName = transactionData["payerName"] as! String
                                let recipientName = transactionData["recipientName"] as! String
                                let userIsPayer = transactionData["userIsPayer"] as! Bool
                                
                                
                                self.confirmedTransaction = Transaction(amount: amount, currency: currency, datetime: datetime, payerID: payerID, recipientID: recipientID, payerName: payerName, recipientName: recipientName, userIsPayer: userIsPayer)
                            }
                            
                            
                            print(self.confirmedTransaction)
                            completion("success (no topup required)")
                        }
                    }
                } else {
                    print("auth failed bro")
//                    self.showAuthenticationError(title: "Oops", message: "Apologies - we couldn't authenticate this transaction. Please try again. ")
                    completion("Apologies - we couldn't authenticate this transaction. Please try again.")
                }
            }
        }
    }
    
    func authenticatePayment(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = "Enter Passcode"
//        context.localizedCancelTitle = "Logout"
        
        context.touchIDAuthenticationAllowableReuseDuration = 5
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            
            let reason = "Authenticate Payment"
            var successfullyAuthenticated = false
            
            DispatchQueue.main.async {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                    [unowned self] success, authenticationError in
                    
                    if success {
                        
                        successfullyAuthenticated = true
                    } else {
    //                            let ac = UIAlertController(title: "Continue", message: "Authentication failed - please try again", preferredStyle: .alert)
    //
    //                            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in }
    //                            ))
    //                            self.present(ac, animated: true)
                        
                        successfullyAuthenticated = false
                    }
                    
                    // return the result - either authentication was successful or not
                    completion(successfullyAuthenticated)
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometrics not available", message: "Your device doesn't seem to be configured for Biometric ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            completion(false)
        }
    }
    
    func updateUserBalanceInFirestore() {
        self.functions.httpsCallable("getCurrentBalance").call() { (result, error) in
            if error != nil {
                
            } else {
                
            }
        }
    }
        
    @objc func loadRecipientProfilePicView(_ uid: String) {

                
        let storageRef = Storage.storage().reference().child("profilePictures").child(uid)

        storageRef.downloadURL { url, error in
            guard let url = url else { return }

//                let processor = DownsamplingImageProcessor(size: self.profilePicView.frame.size)
//                    >> RoundCornerImageProcessor(cornerRadius: 20)
            self.recipientImage.kf.indicatorType = .activity
            
             DispatchQueue.main.async {
                // using Kingfisher library for tidy handling of image download
                self.recipientImage.kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "Logo200px"),
                    options: [
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ])
                {
                    result in
                    switch result {
                        // TODO add better error handling
                    case .success(let value):
                       print("Pic loaded")
                    case .failure(let error):
                        print("Job failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func showAlert(title: String, message: String?, segue: String?, cancel: Bool) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let seg = segue {
                    self.performSegue(withIdentifier: seg, sender: self)
                }
            }))

            if cancel == true {
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
            }
            
            self.present(alert, animated: true)
        }
    }
    
    func showAuthenticationError(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        }))
        
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SignUpViewController {
            let vc = segue.destination as! SignUpViewController
            vc.userIsInPaymentFlow = true
        } else if segue.destination is DisplayReceiptAfterPaymentViewController {
            
            let vc = segue.destination as! DisplayReceiptAfterPaymentViewController
            vc.transaction = self.confirmedTransaction
        }
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}
// I think this is breaking in iOS13..
//extension UIImageView {
//    func load(url: URL) {
//        DispatchQueue.global().async { [weak self] in
//            if let data = try? Data(contentsOf: url) {
//                if let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        self?.image = image
//                    }
//                }
//            }
//        }
//    }
//}
