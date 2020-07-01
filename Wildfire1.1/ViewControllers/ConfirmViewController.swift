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
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import FirebaseFunctions
import LocalAuthentication
import Kingfisher

class ConfirmViewController: UIViewController {
    // TODO this VC is not super well structured - could do with some refactoring in future
    
    let db = Firestore.firestore()
    var handle: AuthStateDidChangeListenerHandle?
    let userUID = Auth.auth().currentUser?.uid
    lazy var functions = Functions.functions(region:"europe-west1")

    // transaction is via dynamic link
    var isDynamicLinkResponder = false
    
    // this is to distinguish "send" type transactions from "scan" - this one isn't used in code logic, only for Analytics
    var isSendTransaction = false
    
    var transactionType: String?
    
    var decryptedString = ""
    var sendAmount = 0
    
    var transactionCurrency: String?
    
    var topupAmount: Int?

    var recipientUID = ""
    
    // no longer needed
//    var recipientName = ""
    
    // these variables are flags to determine logic triggered by the confirm button on the page
    var enoughCredit = false
    var existingPaymentMethod = false
    var shouldReloadView = false
    var transactionCompleted = false
    
    var confirmedTransaction: Transaction?
    
    var alertController: UIAlertController?
    
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var recipientImage: UIImageView!
    
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var dynamicLabel: UILabel!
    @IBOutlet weak var dynamicLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        
        // check whether the user has completed signup flow
        if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
            Utilities.checkForUserAccount()
        }
        
        checkForExistingPaymentMethod()
        
        // this checks the isDynamicLinkResponder and isSendTransaction variables to decide what type of transaction it is - only for Analytics, no functional effects
        determineTransactionType()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if transactionCompleted != true {
            // note: moved this func call from viewDidLoad so that alerts always play nice (specifically, when tapping a dynamic link). Calling a spinner i.e. UIAlertController in viewDidLoad fails because there's nothing for it to load on yet for some reason.
            // the transactionCompleted check is a workaround because the setupRecipientDetails includes a spinner, and that messes with the segue "showSuccessScreen" after the transaction has been completed (since the view technically appears again once the spinner is dismissed)

         
            self.showSpinner(titleText: nil, messageText: nil)
            
            let group = DispatchGroup()
            // there could potentially be two separate error messages, one from each func. The later one will overwrite the former, think this is acceptable
            var errorMessage: String?
            
            group.enter()
            setUpRecipientDetails(recipientUID) { (success, error) in
                if let error = error {
                    errorMessage = error
                }
                
                group.leave()
            }
            
            group.enter()
            getUserBalance() { (success, error) in
                if let error = error {
                    errorMessage = error
                }
                
                group.leave()
            }
            
            group.notify(queue: .main) {
                
                self.removeSpinnerWithCompletion {
                    
                    if let error = errorMessage {
                        
                        // confirmVC can be presented modally (via dynamic links)
                        if self.isBeingPresented {
                            
                            self.dismiss(animated: true) {
                                self.universalShowAlert(title: "Something went wrong", message: error, segue: nil, cancel: false)
                            }
                        } else {
                            
                            self.universalShowAlert(title: "Something went wrong", message: error, segue: "unwindToPay", cancel: false)
                        }
                    }
                }
            }
        }
        
        if shouldReloadView == true {
            
            self.showSpinner(titleText: nil, messageText: nil)
            
            checkForExistingPaymentMethod()
            getUserBalance() { (success, error) in
                self.removeSpinnerWithCompletion {
                    self.universalShowAlert(title: "Something went wrong", message: "Apologies - we're having connectivity issues. Please try again.", segue: nil, cancel: false)
                }
            }
        }
    }
    
    func setUpElements() {
        

        // Style the elements
        Utilities.styleHollowButtonRED(self.backButton)
        Utilities.styleFilledButton(self.confirmButton)
        
        Utilities.styleLabel(self.currentBalance)
        
        currentBalance.isHidden = true
        
        // disable confirm button until recipient details are fully loaded
        confirmButton.isEnabled = false
        
        recipientImage.clipsToBounds = true
        recipientImage.layer.cornerRadius = recipientImage.bounds.height/2
        
        let sendAmountFloat = Float(sendAmount)/100
        // TODO update with appropriate currency
        // display transaction amount front and centre
        amountLabel.text = "£" + String(format: "%.2f", sendAmountFloat)
        
        // in the case that a user has opened a dynamic link, and this vc has been presented, it doesn't sit in a Nav Controller, so the Nav bar is missing. This shouldn't be too much of an issue in this case
        if isDynamicLinkResponder == true {
            let label = UILabel()
            label.frame = CGRect(x: 20, y: 40, width: 200, height: 34)
            label.textAlignment = NSTextAlignment.left
            label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            label.text = "Confirm"
            self.view.addSubview(label)
        }
    }
    
    func setUpRecipientDetails(_ uid: String, completion: @escaping (Bool?, String?)->()) {
        
        loadRecipientProfilePicView(uid)
        
        let docRef = self.db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            
            if error != nil {
                
                completion(nil, "Apologies - there seems to have been a connectivity issue. Please try again.")
                return
            }
            
            if let document = document, document.exists {
//              let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                let userData = document.data()
                
                guard let recipientName = userData?["fullname"] else { return }
                
                self.recipientLabel.text = "\(recipientName)"
                
                completion(true, nil)
                return
                
            } else {
                // something has gone wrong? - user should not have been able to initiate a payment to recipient if recipient doesn't have an account set up
                
                completion(nil, "Apologies - there seems to have been a connectivity issue. Please try again.")
                return
            }
        }
    }
    
    func getUserBalance(completion: @escaping (Bool?, String?)->()) {
        
        let uid = Auth.auth().currentUser!.uid
        
        let docRef = self.db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            
            if error != nil {
                completion(nil, "Apologies - there seems to have been a connectivity issue. Please try again.")
                return
            }
            if let document = document, document.exists {
                
                let userData = document.data()
                
                let userBalance = userData?["balance"] as! Int
                
                // N.B. all database amounts are in cents i.e. £43.50 is '4350'
                let userBalanceFloat = Float(userBalance)/100
                self.currentBalance.text = "Current balance: £\(String(format: "%.2f", (userBalanceFloat)))"
                self.currentBalance.isHidden = false
                let difference = userBalance - self.sendAmount
                
                
                if difference < 0 {
                    let diff = difference*(-1)
                    
                    // we'll need this amount available for transact function to access if user wants to top up
                    self.topupAmount = diff
                    
                    let differenceString = String(format: "%.2f", Float(diff)/100)
                    let totalCharge = String(format: "%.2f", Float(diff + 20)/100)
                    
                    // safeguard topup amount - must be a multiple of 50cents, and >= 50
                    // this should theoretically never be triggered as rules are in place on the receive screen. If it does, it would be better to disrupt users temporarily than let the transactions go through.
                    let check = (diff + 25)/50 * 50
                    
                    if check != diff || diff < 50 || diff > 4000 {
                        
                        Analytics.logEvent("topUpBroken", parameters: nil)
                        
                        completion(false, "This topup amount can't be handled at this time. Please try topping up your account manually.")
                        
                        return
                    }
                    
                    self.dynamicLabel.text = "Tap 'Confirm' to top up £\(differenceString) and pay."
                    self.dynamicLabel2.text = "(Card charge: 20p. Total charge: £\(totalCharge).)"
                    
                    self.enoughCredit = false
                    
                } else {
                    
                    
                    let diffFloat = String(format: "%.2f", Float(difference)/100)
                    self.dynamicLabel.text = "Your remaining balance will be £\(diffFloat)."
                    self.enoughCredit = true
                }
                
                // show these two labels (initially hidden)
                self.currentBalance.isHidden = false
                self.dynamicLabel.isHidden = false
                
                self.confirmButton.isEnabled = true
                
                completion(true, nil)
                return
                
            } else {
                // user hasn't added account info yet
                
                self.dynamicLabel.text = "Please provide some quick details to complete payment"
                
                self.confirmButton.setTitle("Continue", for: .normal)
                
                self.dynamicLabel.isHidden = false
                self.confirmButton.isEnabled = true
                
                completion(true, nil)
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
    
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        
        let userAccountExists = UserDefaults.standard.bool(forKey: "userAccountExists")
        if userAccountExists == true {
            
            
            // notice user doesn't strictly need to add card details if they already have sufficient credit to complete payment - this is intentional
            if enoughCredit == true {
                
                // initiate transaction
                
                transact(recipientUID: self.recipientUID, amount: self.sendAmount, topup: false, topupAmount: nil) { result in
                    
                    let trunc = result.prefix(7)
                    if trunc == "success" {
                        
                        
                        if let type = self.transactionType, let currency = self.transactionCurrency {
                            
                            let topupAmount = 0
                      
                            // amount should be human readable i.e. in natual currency amount
                            let realSendAmount = Float(self.sendAmount)/100
                            
                            Analytics.logEvent(Event.paymentSuccess.rawValue, parameters: [
                                EventVar.paymentSuccess.paidAmount.rawValue: realSendAmount,
                                EventVar.paymentSuccess.currency.rawValue: currency,
                                EventVar.paymentSuccess.recipient.rawValue: self.recipientUID,
                                EventVar.paymentSuccess.topup.rawValue: topupAmount,
                                EventVar.paymentSuccess.transactionType.rawValue: type
                            ])
                        }
                        
                        self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                    } else {
                        
                        self.universalShowAlert(title: "Something went wrong", message: result, segue: nil, cancel: false)
                    }
                    
                }
            } else {
                if existingPaymentMethod == true {
                    
                    // initiate topup (ideally with ApplePay & touchID)
                    transact(recipientUID: self.recipientUID, amount: self.sendAmount, topup: true, topupAmount: self.topupAmount) { result in
                        
                        let trunc = result.prefix(7)
                        if trunc == "success" {
                            
                            if let type = self.transactionType {
                                
                                var topupAmount = 0
                                
                                // since there was a topup, get the amount to add it to the Analytics event
                                if let topup = self.topupAmount {
                                    topupAmount = topup
                                }
                                
                                Analytics.logEvent(Event.paymentSuccess.rawValue, parameters: [
                                    EventVar.paymentSuccess.paidAmount.rawValue: self.sendAmount,
                                    EventVar.paymentSuccess.recipient.rawValue: self.recipientUID,
                                    EventVar.paymentSuccess.topup.rawValue: topupAmount,
                                    EventVar.paymentSuccess.transactionType.rawValue: type
                                ])
                            }

                            self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                        } else {
                            self.universalShowAlert(title: "Something went wrong", message: result, segue: nil, cancel: false)
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
    
    // N.B. the meat and bones of what happens in a transaction now lives in Cloud Functions
    func transact(recipientUID: String, amount: Int, topup: Bool, topupAmount: Int?, completion: @escaping (String) -> Void) {
        
        
        // for sake of readibility, we first divide into two cases: 1) user wants to topup and transact, 2) user just wants to transact - they already have sufficient credit.
        // update: refactor this at some point...
        
        if topup == true {
            authenticatePayment() { authenticated in
                if authenticated == true {
                    self.showSpinner(titleText: "Authorizing", messageText: "Securely transferring funds")
                    
                    // N.B. topupAmount must be passed if topup == true. Guarding so that this breaks if this condition isn't met.
                    // this should never break
                    guard let tpa = topupAmount else {
                        self.universalShowAlert(title: "Something went wrong", message: "Please restart the application, and contact support@wildfirewallet.com if the problem persists", segue: nil, cancel: false)
                        Analytics.logEvent("topupAmountMissing", parameters: nil)
                        return
                    }
                                        
                    self.functions.httpsCallable("createPayin").call(["amount": tpa, "currency": "GBP"]) { (result, error) in
                        if error != nil {
                            self.removeSpinnerWithCompletion() {
                                completion("We couldn't top up your account. Please try again.")
                            }
                        } else {
                            
                            self.functions.httpsCallable("getCurrentBalance").call(["foo": "bar"]) { (result, error) in
                                
                                // not too fussed if this fails or not - this just triggers the updating of balance in firestore db
                            }
                                    
                            self.functions.httpsCallable("transact").call(["recipientUID": recipientUID, "amount": amount, "currency": "GBP"]) { (result, error) in
                                
                                if let error = error {
                                                                    
                                    self.removeSpinnerWithCompletion() {
                                        
                                        if error.localizedDescription != "" {
                                            
                                            completion(error.localizedDescription)
                                        } else {
                                            
                                            completion("Something went wrong. Please try again.")
                                        }
                                    }
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
                                        
                                        self.transactionCompleted = true
                                        
                                        self.removeSpinnerWithCompletion {
                                            
                                            completion("success (topped up)")
                                        }
                                    } else {
                                        self.removeSpinnerWithCompletion {
                                            completion("Transaction was successful but the connection dropped - please check your receipts to confirm it went through.")
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    completion("Apologies - we couldn't authenticate this transaction. Please try again. ")
                }
            }
        } else {
            authenticatePayment() { authenticated in
                if authenticated == true {
                    self.showSpinner(titleText: "Authorizing", messageText: "Securely transferring funds")
                    
                    self.functions.httpsCallable("transact").call(["recipientUID": recipientUID,  "amount": amount, "currency": "GBP"]) { (result, error) in
                    
                        if let error = error {
                                                        
                            self.removeSpinnerWithCompletion() {
                                
                                if error.localizedDescription != "" {
                                    
                                    completion(error.localizedDescription)
                                } else {
                                    
                                    completion("Please try again.")
                                }
                            }
                        } else {
                            
                            print("result is: \(result?.data)")
                            
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
                                
                                self.transactionCompleted = true
                                
                                self.removeSpinnerWithCompletion() {
                                    completion("success (no topup required)")
                                }
                            } else {
                                
                                self.removeSpinnerWithCompletion() {
                                    completion("Transaction was successful but the connection dropped - please check your receipts to confirm it went through.")
                                }
                            }
                            
                            
                        }
                    }
                } else {
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
            
            DispatchQueue.main.async {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                    [unowned self] success, authenticationError in
                    
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
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
    
    func determineTransactionType() {
        if isSendTransaction == true {
            self.transactionType = "send"
        } else if isDynamicLinkResponder == true {
            self.transactionType = "dynamicLink"
        } else {
            self.transactionType = "scan"
        }
    }
        
    @objc func loadRecipientProfilePicView(_ uid: String) {

                
        let storageRef = Storage.storage().reference().child("profilePictures").child(uid)

        storageRef.downloadURL { url, error in
            guard let url = url else { return }

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
    
    @IBAction func backButtonPresed(_ sender: Any) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SignUpViewController {
            let vc = segue.destination as! SignUpViewController
            vc.userIsInPaymentFlow = true
        } else if segue.destination is DisplayReceiptAfterPaymentViewController {
            
            let vc = segue.destination as! DisplayReceiptAfterPaymentViewController
            vc.transaction = self.confirmedTransaction
            if self.isDynamicLinkResponder == true {
                vc.isDynamicLinkResponder = true
            }
        }
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}

