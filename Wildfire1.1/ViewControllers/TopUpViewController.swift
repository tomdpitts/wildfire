//
//  TopUpViewController.swift
//  Wildfire1.1
//
//  Created by Tom Daniel on 15/04/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import LocalAuthentication

class TopUpViewController: UIViewController, UITextFieldDelegate {
    
    lazy var functions = Functions.functions(region: "europe-west1")
    
    var currentBalance: String?
    var creditAmount: Int?
    
    var newBalance: Int?

    @IBOutlet weak var addCredit: UIButton!
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var cardChargeLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.isHidden = true
        
        Utilities.styleHollowButton(addCredit)
        if let balance = currentBalance {
            navigationItem.title = "Balance: £\(balance)"
        } else {
            navigationItem.title = "Balance"
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        amountField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func amountChanged(_ sender: Any) {
        guard let amountString = amountField.text else { return }
        
        var workString: String = amountString
        
        // 1: ensure amount is between 0.50 and 40
        
        guard let amountFloat = Float(workString) else { return }
        
        var x = amountFloat
        
        if x > 40.00 {
            x = 40.00
            self.universalShowAlert(title: "Max amount £40", message: "At this time, Wildfire can only transact amounts up to £40. This limit will be raised soon.", segue: nil, cancel: false)
        }
        
        if x < 0.5 {
            x = 0.5
            self.universalShowAlert(title: "Min amount £0.50", message: "At this time, Wildfire can only transact amounts above £0.50", segue: nil, cancel: false)
        }
        
        // 2: round to nearest 0.50
        
        let y = (Float(Int((2*x) + 0.5)))/2
        
        if x != y {
            self.universalShowAlert(title: "Apologies", message: "Only amounts in 50p increments can be transacted e.g. £3, £3.50, £4 etc.", segue: nil, cancel: false)
        }
        
        // 3: round to 2 decimal places
        
        let z = String(y)
        
        let numberOfDecimalDigits: Int
         
        if let dotIndex = z.firstIndex(of: ".") {
             // prevent more than 2 digits after the decimal
             numberOfDecimalDigits = z.distance(from: dotIndex, to: z.endIndex) - 1
             
             if numberOfDecimalDigits == 1 {
                 let replacementString = z + "0"
                 workString = replacementString
                 
             } else if numberOfDecimalDigits == 0 {
                 let replacementString = String(z.dropLast())
                 workString = replacementString
             }
        }
        
        amountField.text = workString
        guard let amount = Float(workString) else {
            print("couldn't Float workString")
            return }
        
        let totalCharge = String(format: "%.2f", amount + 0.20)
//        let chargedAmount = amount + 0.20
//        let finalChargedAmount = String(chargedAmount) + "0"
        cardChargeLabel.text = "The card charge is 20p so you'll be charged £\(totalCharge)"
        
        
    }
    
    
    @IBAction func addCreditTapped(_ sender: Any) {
        
        self.view.endEditing(true)
        
        let cardsAdded = UserDefaults.standard.integer(forKey: "numberOfCards")
        
        if cardsAdded < 1 {
            universalShowAlert(title: "No payment methods", message: "Please add card details to continue", segue: "showAddCard", cancel: true)
            return
        }
        
        let success = validateAmount()
        if success == true {
            errorLabel.isHidden = true
            if let amount = self.creditAmount {
                
                topUp(amount: amount, currency: "GBP") { (result, amount) in
                    
                    if result != "success" {
                        self.universalShowAlert(title: "Oops", message: result, segue: nil, cancel: false)
                    } else {
                        self.newBalance = amount
                        self.performSegue(withIdentifier: "showCreditAdded", sender: self)
                    }
                }
            }
            
            
        } else {
            return
        }
    }
    
    func topUp(amount: Int, currency: String, completion: @escaping (String, Int?) -> Void) {
        
        authenticatePayment() { authenticated in
            if authenticated == true {
            
                self.showSpinner(titleText: "Authorizing", messageText: "Adding credit to balance")
                
                self.functions.httpsCallable("createPayin").call(["amount": amount, "currency": currency]) { (result, error) in
                    if error != nil {
                        // TODO
                        self.removeSpinner()
                        completion("We couldn't top up your account. Please try again.", nil)
                    } else {
                        
                        self.functions.httpsCallable("getCurrentBalance").call(["foo": "bar"]) { (result, error) in
                            
                            if error != nil {
                                self.removeSpinner()
                                completion("Your account was successfully credited but the connection dropped. Please restart the app to see the correct balance in your account.", nil)
                            } else {
                                
                                if let data = result?.data {
                                    let newBalance = data as? Int
                                    self.removeSpinner()
                                    completion("success", newBalance)
                                }
                                
                            }
                        }
                    }
                }
            } else {
                completion("Adding credit could not be authorized. Please try again.", nil)
            }
        }
    }
    
    func validateAmount() -> Bool {
        if let text = amountField.text {
            if text == "" {
                errorLabel.text = "Please enter a valid amount"
                errorLabel.isHidden = false
                return false
            } else {
                if let m = Float(text) {
                    self.creditAmount = Int(m*100)
                    return true
                } else {
                    errorLabel.text = "Please enter a valid number"
                    errorLabel.isHidden = false
                    return false
                }
            }
        } else {
            return false
        }
    }
            
    func authenticatePayment(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = "Enter Passcode"
        
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
                        successfullyAuthenticated = false
                    }
                    
                    // return the result - either authentication was successful (true) or not (false)
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            return true
        }

        let newText = oldText.replacingCharacters(in: r, with: string)
        let isNumeric = newText.isEmpty || (Double(newText) != nil)
        let numberOfDots = newText.components(separatedBy: ".").count - 1

        let numberOfDecimalDigits: Int
        if let dotIndex = newText.firstIndex(of: ".") {
            // prevent more than 2 digits after the decimal
            numberOfDecimalDigits = newText.distance(from: dotIndex, to: newText.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }

        return isNumeric && numberOfDots <= 1 && numberOfDecimalDigits <= 2
    }
    
    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is CreditAddedSuccessViewController {
            let vc = segue.destination as! CreditAddedSuccessViewController
            if let newBalance = self.newBalance {
                vc.newBalance = newBalance
            }
        }
    }
}
