//
//  BankDetails1TableViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class BankDetails1TableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var sortCodeField: UITextField!
    @IBOutlet weak var accountField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var nextButton: UIButton!
    
    
    var line1 = ""
    var line2 = ""
    var cityName = ""
    var region = ""
    var postcode = ""
    var country = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true
        
        Utilities.styleTextField(nameField)
        Utilities.styleTextField(sortCodeField)
        Utilities.styleTextField(accountField)
        
        nameField.delegate = self
        sortCodeField.delegate = self
        accountField.delegate = self
        
        Utilities.styleHollowButton(nextButton)
        
        nameField.becomeFirstResponder()
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        
        getUserAddress()
    }

    @IBAction func submitPressed(_ sender: Any) {
        
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
            return
        } else {
            performSegue(withIdentifier: "goToStep2", sender: self)
        }
    }
    
    func getUserAddress() {
        if let uid = Auth.auth().currentUser?.uid {
            let docRef = Firestore.firestore().collection("users").document(uid)

//
//            docRef.getDocument { (document, error) in
//
//                if let err = error {
//                    print(err)
//                }
//                if let document = document, document.exists {
//                    let data = document.data()
//                    print(data)
//                } else {
//                    print("Document does not exist")
//                }
//            }
            
            docRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {

                    print("Error fetching document: \(error!)")
                    return
                }
                
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                
                if let address = data["defaultBillingAddress"] as? [String: String] {
                    self.line1 = address["line1"] ?? ""
                    self.line2 = address["line2"] ?? ""
                    self.cityName = address["city"] ?? ""
                    self.region = address["region"] ?? ""
                    self.postcode = address["postcode"] ?? ""
                    self.country = address["country"] ?? ""
                    
                } else { return }
            }
        }
    }

    func validateFields() -> String? {
        
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let sortCode = sortCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let accountNumber = accountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return "Please fill in all fields" }
        
        
        // Check that all fields are filled in
        if name == "" ||
            sortCode == "" ||
            accountNumber == ""
            {
            return "Please fill in all fields"
            
        } else {
    
            // N.B. Sort code contains two dashes i.e. xx-xx-xx
            if sortCode.count != 8 {
                return "Sort code should be 6 digits"
                }
            if accountNumber.count > 9 || accountNumber.count < 8 {
                return "Account number must be either 8 or 9 digits"
                }
        }
        
        return nil
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // allow deletion
        if string == "" {
            return true
        }
        
        if textField == sortCodeField {
            
            let allowedCharacters = CharacterSet(charactersIn:"0123456789-")
            let characterSet = CharacterSet(charactersIn: string)
            
            if allowedCharacters.isSuperset(of: characterSet) {
                if let sortCodeString = sortCodeField.text {
                    
                    if sortCodeString.count == 2 {
                        let replacement = sortCodeString + "-" + string
                        sortCodeField.text = replacement
                        
                        return false
                    } else if sortCodeString.count == 5 {
                        // N.B. count is 5 because of the dash: "xx-xx" has 5 characters
                        let replacement = sortCodeString + "-" + string
                        sortCodeField.text = replacement
                        
                        return false
                    } else {
                        return true
                    }
                    
                } else {
                    // this should never be triggered
                    return true
                }
            } else {
                return allowedCharacters.isSuperset(of: characterSet)
            }
            
        } else if textField == accountField {
            
            let allowedCharacters = CharacterSet(charactersIn:"0123456789")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
            
        } else {
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == nameField {
            sortCodeField.becomeFirstResponder()
        } else if textField == sortCodeField {
            accountField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
         if segue.destination is BankDetails2TableViewController {
            let vc = segue.destination as! BankDetails2TableViewController
            
            guard let name = nameField.text, let sortCode = sortCodeField.text, let accountNumber = accountField.text else { return }
            
            // strip out the dashes
            let sortCodeFormatted = sortCode.replacingOccurrences(of: "-", with: "")
            
            vc.name = name
            vc.sortCode = sortCodeFormatted
            vc.accountNumber = accountNumber
            
            vc.line1 = self.line1
            vc.line2 = self.line2
            vc.cityName = self.cityName
            vc.region = self.region
            vc.postcode = self.postcode
            // this shouldn't be passed straight to the text field as it needs to be translated from country code to country name i.e. in the database it's "GB", not "United kingdom" - this is because that's how mangopay APIs require country
            vc.country = self.country
        }
    }

    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
        //        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}
