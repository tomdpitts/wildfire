//
//  ConfirmDepositViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 19/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class ConfirmDepositViewController: UIViewController {
    
    var bankAccount: BankAccount?
    var depositAmount: Float?
    
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
            amountLabel.text = String(n)
        } else {
            amountLabel.text = "not found"
        }
        Utilities.styleHollowButton(confirmDepositButton)
        Utilities.styleHollowButtonRED(cancelButton)
        
        navigationItem.title = "Confirm Deposit"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    
    @IBAction func confirmDepositTapped(_ sender: Any) {
        
        if let bnk = bankAccount, let amount = depositAmount {
            
            self.functions.httpsCallable("").call(["amount": tpa, "currency": "EUR"]) { (result, error) in
                                    if error != nil {
                                        // TODO
            //                            self.showAuthenticationError(title: "Oops!", message: "We couldn't top up your account. Please try again.")
                                        completion("We couldn't top up your account. Please try again.")
                                    } else {
            
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
