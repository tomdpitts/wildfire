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
    @IBOutlet weak var confirmDepositButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayBankInfo()
        
        if let n = depositAmount {
            amountLabel.text = String(format: "%.2f", n)
        } else {
            amountLabel.text = "not found"
        }
        Utilities.styleHollowButton(confirmDepositButton)
        Utilities.styleHollowButtonRED(cancelButton)
        
        navigationItem.title = "Confirm Deposit"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    // TODO finish this func
    @IBAction func confirmDepositTapped(_ sender: Any) {
        
        // prevent double taps!
        confirmDepositButton.isEnabled = false
        
        if let amount = depositAmount, let currency = currency {
            
            let amountInCents = Int(amount*100)
            
            self.functions.httpsCallable("triggerPayout").call(["amount": amountInCents, "currency": currency]) { (result, error) in
                if error != nil {
                    // TODO
//                            self.showAuthenticationError(title: "Oops!", message: "We couldn't top up your account. Please try again.")
                    print("There was an issue in processing your deposit, please try again")
                    self.confirmDepositButton.isEnabled = true
                } else {
                    self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                    
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

}
