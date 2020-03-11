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

    @IBOutlet weak var KYCPendingView: UIView!
    
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
        
        KYCPendingView.clipsToBounds = true
        KYCPendingView.layer.borderWidth = 2 //Or some other value
        KYCPendingView.layer.borderColor = UIColor(hexString: "#39C3C6").cgColor

        Utilities.styleHollowButton(makeDepositButton)
        Utilities.styleHollowButtonRED(deleteButton)
        
        // TODO - TAKE THIS OUT! FOR TESTING ONLY
//        navigationItem.title = "Account Details"
//        navigationController?.navigationBar.prefersLargeTitles = true
        
        UserDefaults.standard.set(false, forKey: "KYCPending")
        UserDefaults.standard.set(false, forKey: "KYCVerified")
        
        if UserDefaults.standard.bool(forKey: "KYCPending") != true { 
            KYCPendingView.isHidden = true
        }
    }

    @IBAction func makeDepositTapped(_ sender: Any) {
        
        let KYCVerified = UserDefaults.standard.bool(forKey: "KYCVerified")
        let KYCPending = UserDefaults.standard.bool(forKey: "KYCPending")
        
        
        if KYCPending == true {
            performSegue(withIdentifier: "showPendingView", sender: self)
        } else {
            if KYCVerified == true {
                performSegue(withIdentifier: "showDepositAmountView", sender: self)
            } else {
                performSegue(withIdentifier: "showKYCView", sender: self)
            }
        }
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
