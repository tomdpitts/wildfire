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
    @IBOutlet weak var sortCodeLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var IBANStack: UIStackView!
    @IBOutlet weak var swiftStack: UIStackView!
    @IBOutlet weak var accountNumberStack: UIStackView!
    @IBOutlet weak var sortCodeStack: UIStackView!
    @IBOutlet weak var countryStack: UIStackView!

    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var confirmDepositButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
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
    }
    
    // TODO finish this func
    @IBAction func confirmDepositTapped(_ sender: Any) {
        
        self.showSpinner(titleText: "Ordering deposit", messageText: nil)
        
        // prevent double taps!
        confirmDepositButton.isEnabled = false
        
        if let amount = depositAmount, let currency = currency {
            
            let amountInCents = Int(amount*100)
            
            self.functions.httpsCallable("triggerPayout").call(["amount": amountInCents, "currency": currency]) { (result, error) in
                
                self.removeSpinnerWithCompletion {
                    
                    if error != nil {
                        
                        self.universalShowAlert(title: "Something went wrong", message: "Sorry about this. It's not clear what went wrong exactly, although it may have been the internet connection. Please check your balance and if it's unchanged, try depositing again. (If the problem persists, contact support@wildfirewallet.com)", segue: nil, cancel: false)
                        
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
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    func displayBankInfo() {
        
        if let bnk = bankAccount {
                        
            accountOwnerLabel.text = bnk.accountHolderName
            
            if let iban = bnk.IBAN {
                IBANLabel.text = iban
            } else {
                IBANStack.isHidden = true
            }
            
            if let swift = bnk.SWIFTBIC {
                swiftLabel.text = swift
            } else {
                swiftStack.isHidden = true
            }
            
            if let number = bnk.accountNumber {
                accountNumberLabel.text = number
            } else {
                accountNumberStack.isHidden = true
            }
            
            if let sort = bnk.sortCode {
                sortCodeLabel.text = sort
            } else {
                sortCodeStack.isHidden = true
            }
            
            if let country = bnk.country {
                countryLabel.text = country
            } else {
                countryStack.isHidden = true
            }
        }
    }
}
