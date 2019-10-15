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
    
    @IBOutlet var nationalityField: UITextField! = UITextField()
    
    @IBOutlet var residenceField: UITextField! = UITextField()
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
    
        // Validate the fields
        let error = validateFields()
        
        // Create cleaned versions of the data
        self.firstNameClean = firstName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if SignUpViewController().userIsInPaymentFlow == true {
            // Transition to step 2 aka PaymentSetUp VC
            self.performSegue(withIdentifier: "goToAddPayment", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindToAccountViewID", sender: self)
        }
    }
    
    var countries: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.isHidden = true
        
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            self.countries.append(name)
        }
        print(self.countries)
        
//        title = "Auto-Complete"
        
//        edgesForExtendedLayout = UIRectEdge()
        nationalityField.delegate = self
        residenceField.delegate = self
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
    
    func addMangoPayUser() {
        
        let suvc = SignUpViewController()
        let f2vc = formStep2ViewController()
        var nationality = ""
        var residence = ""
        
        if let nat = nationalityField.text {
            
            // TODO check submitted text against locale list - if it returns an error, display that as error message to user
            let natClean = nat.trimmingCharacters(in: .whitespacesAndNewlines)
            let nationality = locale(for: natClean)
        }
        
        if let res = nationalityField.text {
            residence = locale(for: res)
        }
        
        
        // Create the user
        Auth.auth().createUser(withEmail: suvc.emailClean, password: suvc.passwordClean) { (result, err) in
            
            // Check for errors
            if err != nil {
                
                // There was an error creating the user
                self.showError("Error creating user")
            }
            else {
                
                // User was created successfully, now store the first name and last name
                let db = Firestore.firestore()
                
                
                db.collection("users").document(result!.user.uid).setData(["firstname": suvc.firstNameClean,
                   "lastname": suvc.lastNameClean,
                   "email": suvc.emailClean,
                   "dob": f2vc.dob,
                   "nationality": nationality,
                   "residence": residence,
                   "balance": 0,
                   "photoURL": "https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png" ]) { (error) in
                    
                    //                        print(result!.user.uid)
                    if error != nil {
                        // Show error message
                        self.showError("Error saving user data")
                    }
                }
                
            }
            
        }
    }
    
    private func locale(for fullCountryName : String) -> String {
        var locales : String = ""
        for localeCode in NSLocale.isoCountryCodes {
            let identifier = NSLocale(localeIdentifier: localeCode)
            let countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: localeCode)
            if fullCountryName.lowercased() == countryName?.lowercased() {
                return localeCode
            }
        }
        return locales
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.alpha = 1
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
