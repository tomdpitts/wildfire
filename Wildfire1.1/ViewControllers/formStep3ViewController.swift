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
import FirebaseFunctions
import FirebaseAnalytics

class formStep3ViewController: UIViewController, UITextFieldDelegate {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var userIsInPaymentFlow = false
    
    var firstname = ""
    var lastname = ""
    var email = ""
//    var password = ""
    var dob: Int64?
    
    @IBOutlet var nationalityField: UITextField! = UITextField()
    
    @IBOutlet var residenceField: UITextField! = UITextField()
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    var countries: [String] = []
    
    let alternativeUKNames = ["U.K.", "British", "Great Britain", "England"]
    let alternativeUSNames = ["U.S.", "U.S.A."]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // add the alternative names to the list of answers for Nationality and Residence
        self.countries.append(contentsOf: alternativeUKNames)
        self.countries.append(contentsOf: alternativeUSNames)
        
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            self.countries.append(name)
        }
        
//        title = "Auto-Complete"
        
//        edgesForExtendedLayout = UIRectEdge()
        nationalityField.delegate = self
        residenceField.delegate = self
        
        setUpElements()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // There's something wrong with the fields, show error message
            showError(error!)
            return
        } else {
            
            let nationality = localeFinder(for: nationalityField.text!)
            let residence = localeFinder(for: residenceField.text!)
            
            addNewUserToDatabases(firstname: self.firstname, lastname: self.lastname, email: self.email, dob: self.dob!, nationality: nationality!, residence: residence!)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // both fields require this, so no if condition required
        
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
                let reverted = country.localizedCapitalized
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
    
    // not adding validation to check for existing doc as that should already be covered
    func addNewUserToDatabases(firstname: String, lastname: String, email: String, dob: Int64, nationality: String, residence: String) {
        
        self.showSpinner(titleText: nil, messageText: nil)
        
        let fullname = firstname + " " + lastname
        
        var fcmToken = ""
        
        if let token = UserDefaults.standard.string(forKey: "fcmToken") {
            fcmToken = token
        }
        
        if let uid = Auth.auth().currentUser?.uid {
            
            let newUserData: [String : Any] = ["firstname": firstname,
            "lastname": lastname,
            "fullname": fullname,
            "email": email,
            "dob": dob,
            "nationality": nationality,
            "residence": residence,
            // tried having the balance added via Cloud Function (onCreate for user in Firestore) but it's just too slow - frequent crashes in testing due to the Account Listener being too quick..
            "balance": 0,
            "fcmToken": fcmToken,
            "timestamp": FieldValue.serverTimestamp(),
            // TODO if facebook login, use profile pic here
                "photoURL": "https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png" ]
            
            Firestore.firestore().collection("users").document(uid).setData(newUserData, merge: true) { (error) in
                
                self.removeSpinnerWithCompletion {
                    // print(result!.user.uid)
                     if error != nil {
                        
                         // Show error message
                         self.showAlert(title: "Error saving user data", message: nil, progress: false)
                     } else {
                        
                        // update saved userAccountExists flag
                        if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
                            Utilities.checkForUserAccount()
                        }
                        
                        Analytics.logEvent(Event.accountAdded.rawValue, parameters: nil)
                        
                        Utilities.getMangopayID()
                        self.performSegue(withIdentifier: "showAccountAdded", sender: self)
                         
                        
                        // the user is already logged in with their phone number, but adding email address gives a killswitch option
                        // for future ref - we might want to add email to User as well (easy to do, allows for checking of dupe emails... but not sure this is actually something that's needed so commenting out for now)
                        // self.addEmailToFirebaseUser()
                        
                        
                    }
                }
            }
        }
    }
    
    func showAlert(title: String?, message: String?, progress: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
//            if progress == true {
//                self.progressUser()
//            }
        }))
        self.present(alert, animated: true)
    }
    
    func localeFinder(for fullCountryName : String) -> String? {
        
        var name = ""
        
        // accept common alternative answers for Nationality or Residence
        if alternativeUKNames.contains(fullCountryName) {
            name = "United Kingdom"
        } else if alternativeUSNames.contains(fullCountryName) {
            name = "United States"
        } else {
            name = fullCountryName
        }
        
        let fullCountryNameClean = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for localeCode in NSLocale.isoCountryCodes {
            let identifier = NSLocale(localeIdentifier: "en_UK")
            let countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: localeCode)
            
            let countryNameClean = countryName!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if fullCountryNameClean == countryNameClean {
                return localeCode
            }
        }
        
        // if for loop ends without returning a value, the country entered could not be found
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
        // let's check the entered text is valid
        
        // (we can force unwrap these because if this code is only triggered if there is some text in both)
        let nationality = localeFinder(for: nationalityField.text!)
        let residence = localeFinder(for: residenceField.text!)
        
        if nationality == nil {
            return "Please enter a valid Nationality"
        }
        
        if residence == nil {
            return "Please enter a valid Country of Residence"
        } else {
        
            // blockedCountriesList is a universal constant
            let list = blockedCountriesList
            
            var localeList: [String] = []
            
            for x in list {
                if let y = localeFinder(for: x) {
                    localeList.append(y)
                }
            }
        
            let result = localeList.filter { $0 == residence }
            
            if result.isEmpty == false {
                return "Regrettably, due to the anti-money laundering policies of our payment processor, we are unable to add users with Residence in \(residenceField.text!)."
            }
        }
        
        return nil
    }
    
    func setUpElements() {
            
        // Hide the error label
        errorLabel.isHidden = true
        
        // Style the elements
        Utilities.styleTextField(nationalityField)
        Utilities.styleTextField(residenceField)
        Utilities.styleFilledButton(confirmButton)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AccountAddedViewController {
            let vc = segue.destination as! AccountAddedViewController
            vc.userIsInPaymentFlow = self.userIsInPaymentFlow
        }
    }
    
    @objc func DismissKeyboard(){
        // Causes the view to resign from the status of first responder.
        view.endEditing(true)
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
