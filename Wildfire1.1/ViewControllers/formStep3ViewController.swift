//
//  formStep3ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 15/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class formStep3ViewController: UIViewController, UITextFieldDelegate {
    
    var userIsInPaymentFlow = false
    
    var firstname = ""
    var lastname = ""
    var email = ""
    var password = ""
    var dob: Int64?
    
    @IBOutlet var nationalityField: UITextField! = UITextField()
    
    @IBOutlet var residenceField: UITextField! = UITextField()
    
    @IBOutlet weak var errorLabel: UILabel!
    
    var countries: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.isHidden = true
        
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            self.countries.append(name)
        }
        
//        title = "Auto-Complete"
        
//        edgesForExtendedLayout = UIRectEdge()
        nationalityField.delegate = self
        residenceField.delegate = self
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // There's something wrong with the fields, show error message
            showError(error!)
            return
        } else {
            
            // let's check the entered text is valid
            
            // (we can force unwrap these because if this code is only triggered if there is some text in both)
            let nationality = localeFinder(for: nationalityField.text!)
            let residence = localeFinder(for: residenceField.text!)
            
            if nationality == nil {
                showError("Please enter a valid Nationality")
                return
            }
            if residence == nil {
                showError("Please enter a valid Country of Residence")
                return
            }
            
            addNewUser(firstname: self.firstname, lastname: self.lastname, email: self.email, password: self.password, dob: self.dob!, nationality: nationality!, residence: residence!)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !autoCompleteText(in: textField, using: string, suggestions: self.countries)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
            confirmButtonTapped(self)
        }
        return true
    }
    
    func autoCompleteText(in textField: UITextField, using string: String, suggestions: [String]) -> Bool {
        if !string.isEmpty,
            let selectedTextRange = textField.selectedTextRange, selectedTextRange.end == textField.endOfDocument,
            let prefixRange = textField.textRange(from: textField.beginningOfDocument, to: selectedTextRange.start),
            let text = textField.text(in: prefixRange) {
            
            let prefix = text + string
            let lowercasePrefix = prefix.lowercased()
            
            var lowercasedCountries: [String] = []
            for country in suggestions  {
                let new = country.lowercased()
                lowercasedCountries.append(new)
            }
            
            let matches = lowercasedCountries.filter { $0.hasPrefix(lowercasePrefix) }
            
            var fixedCountries: [String] = []
            for country in matches  {
                let reverted = country.firstUppercased
                fixedCountries.append(reverted)
            }
            
            if (fixedCountries.count > 0) {
                textField.text = fixedCountries[0]
                
                if let start = textField.position(from: textField.beginningOfDocument, offset: prefix.count) {
                    textField.selectedTextRange = textField.textRange(from: start, to: textField.endOfDocument)
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    func addNewUser(firstname: String, lastname: String, email: String, password: String, dob: Int64, nationality: String, residence: String) {
        
        // Create the user
        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            // TODO need a spinner here to wait for result!
            
            // Check for errors
            if err != nil {
                // There was an error creating the user
                self.showAlert(message: "Error creating user", progress: false)
            } else {
                
                // User was created successfully, now store the first name and last name
                Firestore.firestore().collection("users").document(result!.user.uid).setData(["firstname": firstname,
                   "lastname": lastname,
                   "email": email,
                   "dob": dob,
                   "nationality": nationality,
                   "residence": residence,
                   "balance": 0,
                   "photoURL": "https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png" ]) { (error) in
                    
                    // print(result!.user.uid)
                    if error != nil {
                        // Show error message
                        self.showAlert(message: "Error saving user data", progress: false)
                    } else {
                        self.showAlert(message: "Great! You're signed up.", progress: true)
                    }
                }
            }
        }
    }
    
    func progressUser() {
        if self.userIsInPaymentFlow == true {
            // Transition to step 2 aka PaymentSetUp VC
            self.performSegue(withIdentifier: "goToAddPayment", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindToAccountView", sender: self)
        }
    }
    
    func showAlert(message: String, progress: Bool) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            if progress == true {
                self.progressUser()
            }
        }))
        self.present(alert, animated: true)
    }
    
    private func localeFinder(for fullCountryName : String) -> String? {
        
        for localeCode in NSLocale.isoCountryCodes {
            let identifier = NSLocale(localeIdentifier: "en_UK")
            let countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: localeCode)
            
            let countryNameClean = countryName!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let fullCountryNameClean = fullCountryName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if fullCountryNameClean == countryNameClean {
                return localeCode
            }
        }
        return nil
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    // Check the fields and validate. If everything kosher, this func returns nil, otherwise it returns the error message
    func validateFields() -> String? {
        
        // Check that all fields are filled in
        if nationalityField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            residenceField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "Please fill in all fields."
        }
        return nil
    }
    
}

extension StringProtocol {
    var firstUppercased: String {
        return prefix(1).uppercased()  + dropFirst()
    }
    var firstCapitalized: String {
        return prefix(1).capitalized + dropFirst()
    }
}
