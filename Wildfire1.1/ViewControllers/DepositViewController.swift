//
//  DepositViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 19/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class DepositViewController: UIViewController {
    
    var bankAccount: BankAccount?
    var depositAmount: Float?
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        errorLabel.isHidden = true
        Utilities.styleHollowButton(sendButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        amountTextField.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" {return true}
        return string.rangeOfCharacter(from: CharacterSet(charactersIn: "1234567890.")) == nil ? false : true
    }
    
    func validateAmount() -> Bool {
        if amountTextField.text == "" {
            errorLabel.text = "Please enter an amount to deposit"
            errorLabel.isHidden = false
            return false
        } else {
            if let n = amountTextField.text {
                
                if let m = Float(n) {
                    self.depositAmount = m
                    return true
                } else {
                    // TODO error handling
                    errorLabel.text = "Please enter a valid number"
                    errorLabel.isHidden = false
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        let validated = validateAmount()
        if validated == true {
            performSegue(withIdentifier: "showConfirmDepositView", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let cdVC = segue.destination as? ConfirmDepositViewController {
            
            cdVC.bankAccount = self.bankAccount
            cdVC.depositAmount = self.depositAmount
        }
    }
}
