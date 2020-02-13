//
//  BankDetails1TableViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class BankDetails1TableViewController: UITableViewController {
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var swiftField: UITextField!
    
    @IBOutlet weak var accountField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true
        
        Utilities.styleHollowButton(nextButton)
        
        nameField.becomeFirstResponder()
        
        navigationItem.title = "Bank Account"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func submitPressed(_ sender: Any) {
        
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
        } else {
            performSegue(withIdentifier: "goToStep2", sender: self)
        }
    }

    func validateFields() -> String? {
        
        let name = nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let swiftCode = swiftField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountNumber = accountField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        // Check that all fields are filled in
        if name == "" ||
            swiftCode == "" ||
            accountNumber == ""
            {
            return "Please fill in all fields."
            
        } else {
    
            if swiftCode.count != 6 {
                return "Expiry Date should be in format MMYY"
                }
            if accountNumber.count > 9 || accountNumber.count < 8 {
                return "Account number must be either 8 or 9 digits"
                }
        }
        return nil
    }
        
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
         if segue.destination is BankDetails2TableViewController {
            let vc = segue.destination as! BankDetails2TableViewController
            vc.name = nameField.text!
            vc.swiftCode = swiftField.text!
            vc.accountNumber = accountField.text!
        }
    }
        
    //MARK - UITextField Delegates
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == swiftField || textField == accountField {
            let allowedCharacters = CharacterSet(charactersIn:"0123456789")//Here change this characters based on your requirement
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }

    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
}
