//
//  ConfirmDepositViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 19/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions

class ConfirmDepositViewController: UIViewController {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var bankAccount: BankAccount?
    var depositAmount: Float?
    
    // TODO define currency according to user settings
    var currency: String? = "EUR"
    
    @IBOutlet weak var accountOwnerLabel: UILabel!
    @IBOutlet weak var IBANLabel: UILabel!
    @IBOutlet weak var swiftLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var IBANStack: UIStackView!
    @IBOutlet weak var swiftStack: UIStackView!
    @IBOutlet weak var accountNumberStack: UIStackView!
    @IBOutlet weak var countryStack: UIStackView!

    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var whyAmIBeingCharged: UIStackView!
    @IBOutlet weak var confirmDepositButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    let tapRec = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayBankInfo()
        
        if let amount = depositAmount {
            let actualAmount = 0.98*amount + 0.45
            amountLabel.text = String(format: "%.2f", actualAmount)
        } else {
            amountLabel.text = "not found"
        }
        Utilities.styleHollowButton(confirmDepositButton)
        Utilities.styleHollowButtonRED(cancelButton)
        
        tapRec.addTarget(self, action: "tappedView")
        whyAmIBeingCharged.addGestureRecognizer(tapRec)
    }
    
    // TODO finish this func
    @IBAction func confirmDepositTapped(_ sender: Any) {
        
        self.showSpinner(titleText: "Ordering deposit", messageText: nil)
        
        // prevent double taps!
        confirmDepositButton.isEnabled = false
        
        if let amount = depositAmount, let currency = currency {
            
            let amountInCents = Int(amount*100)
            
            self.functions.httpsCallable("triggerPayout").call(["amount": amountInCents, "currency": currency]) { (result, error) in
                
                self.removeSpinner()
                
                if error != nil {
                    
                    // TODO
                    self.showAuthenticationError(title: "Oops!", message: "Top up didn't complete. Please try again.")
                    
                    self.confirmDepositButton.isEnabled = true
                } else {
                    
                    // update balance
                    self.functions.httpsCallable("getCurrentBalance").call(["foo": "bar"]) { (result, error) in
                        if error != nil {
                            // TODO error handling?
                        } else {
                            // nothing - happy days
                        }
                    }
                    // don't need to wait for anything to come back
                    self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                }
            }
        }
    }
    
    func tappedView(){
        self.performSegue(withIdentifier: "showChargesExplainer", sender: self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    func displayBankInfo() {
        if let bnk = bankAccount {
            accountOwnerLabel.text = bnk.accountHolderName
            IBANLabel.text = bnk.IBAN
            swiftLabel.text = bnk.SWIFTBIC
            accountNumberLabel.text = bnk.accountNumber
            countryLabel.text = bnk.country
            
            if bnk.type == "IBAN" {
                swiftStack.isHidden = true
                accountNumberStack.isHidden = true
                countryStack.isHidden = true
            } else if bnk.type == "OTHER" {
                IBANStack.isHidden = true
            }
        }
    }
    
    func showAuthenticationError(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        }))
        
        self.present(alert, animated: true)
    }
}
