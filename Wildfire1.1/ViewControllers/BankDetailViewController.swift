//
//  BankDetailViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 18/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class BankDetailViewController: UIViewController {
    
    var bankAccount: BankAccount?

    @IBOutlet weak var accountOwnerLabel: UILabel!
    @IBOutlet weak var IBANLabel: UILabel!
    @IBOutlet weak var swiftLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var IBANStack: UIStackView!
    @IBOutlet weak var swiftStack: UIStackView!
    @IBOutlet weak var accountNumberStack: UIStackView!
    @IBOutlet weak var countryStack: UIStackView!
    
    
    
    @IBOutlet weak var makeDepositButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayBankInfo()

        Utilities.styleHollowButton(makeDepositButton)
        Utilities.styleHollowButtonRED(deleteButton)
        
        navigationItem.title = "Account Details"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @IBAction func makeDeposit(_ sender: Any) {
        
        
    }
    
    @IBAction func deleteBankAccount(_ sender: Any) {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let dVC = segue.destination as? DepositViewController {
            
            dVC.bankAccount = self.bankAccount
        }
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
        //        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}
