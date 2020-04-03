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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
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
    
    // not adding validation to check for existing doc as that should already be covered
    func addNewUserToDatabases(firstname: String, lastname: String, email: String, dob: Int64, nationality: String, residence: String) {
        
        self.showSpinner(onView: self.view, titleText: nil, messageText: nil)
        
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
            // I tried having the balance added via Cloud Function (onCreate for user in Firestore) but it's just too slow - frequent crashes in testing due to the Account Listener being too quick..
            "balance": 0,
            "fcmToken": fcmToken,
            // TODO if facebook login, use profile pic here
                "photoURL": "https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png" ]
            
            Firestore.firestore().collection("users").document(uid).setData(newUserData, merge: true) { (error) in
                
                self.removeSpinner()
                 // print(result!.user.uid)
                 if error != nil {
                     // Show error message
                     self.showAlert(title: "Error saving user data", message: nil, progress: false)
                 } else {
                    
                    // update saved userAccountExists flag
                    if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
                        Utilities.checkForUserAccount()
                    }
                    
                    self.performSegue(withIdentifier: "showAccountAdded", sender: self)
                     
                    
                    // the user is already logged in with their phone number, but adding email address gives a killswitch option
                    // for future ref - we might want to add email to User as well (easy to do, allows for checking of dupe emails... but not sure this is actually something that's needed so commenting out for now)
                    // self.addEmailToFirebaseUser()
                    
                    
                }
            }
        } else {
            // TODO error handling
            print("couldn't find UID")
        }
    }
    
    // UPDATE don't think this is needed anymore - leaving for reference:
    
    // all users of the app are signed in via Phone Authentication, but we want to add email to the auth as well for the killswitch functionality i.e. if users ever lose their phone and want to terminate their account & deposit all credit to their bank account
//    func addEmailToFirebaseUser() {
//
//        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//
//        if let user = Auth.auth().currentUser {
//
//            user.linkAndRetrieveData(with: credential) { (authResult, error) in
//                // ...
//                if let err = error {
//                    // TODO
//                    // what are the error options here?
//                    self.showAlert(title: "This email is already registered, please use another", message: "You can delete old accounts at wildfirewallet.com", progress: false)
//                }
//            }
//        }
//    }
    
    func showAlert(title: String?, message: String?, progress: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
//            if progress == true {
//                self.progressUser()
//            }
        }))
        self.present(alert, animated: true)
    }
//
//    func progressUser() {
//        if self.userIsInPaymentFlow == true {
//            // Transition to step 2 aka PaymentSetUp VC
//            self.performSegue(withIdentifier: "goToAddPayment", sender: self)
//        } else {
//            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
//        }
//    }
    
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
        // let's check the entered text is valid
        
        // (we can force unwrap these because if this code is only triggered if there is some text in both)
        let nationality = localeFinder(for: nationalityField.text!)
        let residence = localeFinder(for: residenceField.text!)
        
        if nationality == nil {
            return "Please enter a valid Nationality"
            
        }
        if residence == nil {
            return "Please enter a valid Country of Residence"
        }
        
//        let list = ["Afghanistan", "Bahamas", Bosni Herzegovine, Botswana, Cambodge, Corée du Nord, Ethiopie, Ghana, Guyana, Iran, Irak, Laos, Ouganda, Pakistan, Serbie, Sri Lanka, Syrie, Trinité-et-Tobago, Tunisie, Vanuatu, Yemen.]
//        
//        if list.contains(residence) {
//            return "Regrettably, due to the anti-money laundering policies of our payment processor, we are unable to add users with Residence in \(residence)"
//        }
//        
//        if residence =
        
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
