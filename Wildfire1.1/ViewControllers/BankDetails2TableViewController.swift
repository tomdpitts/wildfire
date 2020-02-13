//
//  BankDetails2TableViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class BankDetails2TableViewController: UITableViewController, UITextFieldDelegate {
    
    var name = ""
    var swiftCode = ""
    var accountNumber = ""

    lazy var functions = Functions.functions(region:"europe-west1")
    
    
    var countries: [String] = []
    
    @IBOutlet weak var line1TextField: UITextField!
    @IBOutlet weak var line2TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var postcodeTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Address Details"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        errorLabel.isHidden = true
        Utilities.styleFilledButton(submitButton)
        
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            self.countries.append(name)
        }
        countryTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        line1TextField.becomeFirstResponder()
    }
    

    // TODO rewrite this using Promise
    @IBAction func submitPressed(_ sender: Any) {
            
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
        } else {
            
            // kill the button to prevent retries
            submitButton.isEnabled = false
            
            // Semaphore is used to ensure async API calls aren't triggered before all the relevant data is ready - they have to be sequential
            let semaphore = DispatchSemaphore(value: 1)
            
            guard let line1 = self.line1TextField.text,
                let line2 = self.line2TextField.text,
                let cityName = self.cityTextField.text,
                let region = self.regionTextField.text,
                let postcode = self.postcodeTextField.text,
                let countryCode = self.countryTextField.text else { return }
            
            // TODO translate country back to code
            
            let bankAccountData: [String: String] = [
                "name": self.name,
                "country": countryCode,
                "swiftCode": self.swiftCode,
                "accountNumber": self.accountNumber,
                
                "line1": line1,
                "line2": line2,
                "city": cityName,
                "region": region,
                "postcode": postcode,
                "countryCode": countryCode
            ]
            
            // fields have passed validation - so continue
            functions.httpsCallable("addBankAccount").call([bankAccountData]) { (result, error) in
                
                
                
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !autoCompleteText(in: textField, using: string, suggestions: self.countries)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
            submitPressed(self)
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

    func addAddressToCard(walletID: String, cardID: String, makeDefault: Bool) {
        if let uid = Auth.auth().currentUser?.uid {
            
            print("trying to add address")
            
            guard let line1 = self.line1TextField.text else { return }
            // N.B. line2 is not required - if nothing entered then pass empty string
            let line2 = self.line2TextField.text ?? ""
            // "city" not key value coding-compliant - renamed to "cityName"
            guard let cityName = self.cityTextField.text else { return }
            guard let region = self.regionTextField.text else { return }
            guard let postcode = self.postcodeTextField.text else { return }
            // TODO country needs to be converted to appropriate format
            guard let country = self.countryTextField.text else { return }
            
            let addressData : [String: [String: String]] = [
                "billingAddress": ["line1": line1, "line2": line2,"city": cityName, "region": region,"postcode": postcode,"country": country]
            ]
            // separate variable name because that's how it shows up in Firestore
            let defaultAddressData : [String: [String: String]] = [
                "defaultBillingAddress": ["line1": line1, "line2": line2,"city": cityName, "region": region,"postcode": postcode,"country": country]
            ]
            
            print("trying to add address2")
            print(addressData)
            
        Firestore.firestore().collection("users").document(uid).collection("wallets").document(walletID).collection("cards").document(cardID).setData(addressData
            // merge: true is IMPORTANT - prevents complete overwriting of a document if a user logs in for a second time, for example, which could wipe important data (including the balance..)
            , merge: true) { (error) in
                // print(result!.user.uid)
                if error != nil {
                    // Show error message
                    print("address adding failed1")
                } else {
                Firestore.firestore().collection("users").document(uid).setData(defaultAddressData
                   // merge: true is IMPORTANT - prevents complete overwriting of a document if a user logs in for a second time, for example, which could wipe important data (including the balance..)
                    , merge: true) { (error) in
                       // print(result!.user.uid)
                       if error != nil {
                           // Show error message
                        print("address adding failed2")
                       } else {
                           print("address should have been added")
                       }
                   }
                }
            }
        }
    }
    

    func validateFields() -> String? {
        
        let line1 = line1TextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        // N.B. line 2 is not required
        let cityName = cityTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let region = regionTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let postcode = postcodeTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = countryTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check that all fields are filled in
        if line1 == "" ||
            // N.B. line 2 is not required
            cityName == "" ||
            region == "" ||
            postcode == "" ||
            country == ""
            {
            return "Please fill in all fields."
            
        } else {
            return nil
//                if cardNumber.count != 16 {
//                    return "Card Number must be 16 digits long"
//                    }
//                if expiryDate.count != 4 {
//                    return "Expiry Date should be in format MMYY"
//                    }
//                if csv.count != 3 {
//                    return "CSV number must be exactly 3 digits"
//                    }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
    }
            
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
}
