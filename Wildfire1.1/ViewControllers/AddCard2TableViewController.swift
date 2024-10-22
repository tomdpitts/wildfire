//
//  AddCard2TableViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 04/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import SwiftyJSON

class AddCard2TableViewController: UITableViewController, UITextFieldDelegate {
    
    private let networkingClient = NetworkingClient()
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var cardNumberField = ""
    var expiryDateField = ""
    var csvField = ""
    
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
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        errorLabel.isHidden = true
        
        Utilities.styleTextField(line1TextField)
        Utilities.styleTextField(line2TextField)
        Utilities.styleTextField(cityTextField)
        Utilities.styleTextField(regionTextField)
        Utilities.styleTextField(postcodeTextField)
        Utilities.styleTextField(countryTextField)
        Utilities.styleHollowButton(submitButton)
        
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            self.countries.append(name)
        }
        
        line1TextField.delegate = self
        line2TextField.delegate = self
        cityTextField.delegate = self
        regionTextField.delegate = self
        postcodeTextField.delegate = self
        countryTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        line1TextField.becomeFirstResponder()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    

    // TODO rewrite this using Promise
    @IBAction func submitPressed(_ sender: Any) {
        self.resignFirstResponder()
            
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
            return
            
        } else {
            
            self.showSpinner(titleText: "Adding card", messageText: "Please allow up to 30 seconds")
            
            // kill the button to prevent retries
//            submitButton.isEnabled = false
            
            var accessKey = ""
            var preregistrationData = ""
            var cardRegURL: URL!
            var cardRegID = ""
            var regData = ""
            
            
            // Semaphore is used to ensure async API calls aren't triggered before all the relevant data is ready - they have to be sequential
//            let semaphore = DispatchSemaphore(value: 1)
            
            var mangopayID = ""
            
            if let mpID = UserDefaults.standard.string(forKey: "mangopayID") {
                mangopayID = mpID
            }
            
            // fields have passed validation - so continue
            functions.httpsCallable("createPaymentMethod").call(["walletName": "defaultWallet", "mpID": mangopayID]) { (result, error) in
//                if let error = error as NSError? {
//                    if error.domain == FunctionsErrorDomain {
//                        let code = FunctionsErrorCode(rawValue: error.code)
//                        let message = error.localizedDescription
//                        let details = error.userInfo[FunctionsErrorDetailsKey]
//                    }
//                    // ...
//                }
//                semaphore.wait()
                
                if let error = error {
                    self.removeSpinnerWithCompletion {
                        self.universalShowAlert(title: "Oops", message: "Something went wrong: \(error.localizedDescription)", segue: nil, cancel: false)
                    }
                    return
                }
                
                if let returnedArray = result?.data as? [[String: Any]] {
                // the result includes the bits we need (this is the result of step 4 in the diagram found at the API doc link above)
                    
                    
                    let jsonCardReg = JSON(returnedArray[0])
                    
                    
                    // extract the following values from the returned CardRegistration object
                    if let ak = jsonCardReg["AccessKey"].string {
                        accessKey = ak
                    }
                    
                    if let prd = jsonCardReg["PreregistrationData"].string {
                        preregistrationData = prd
                    }
                    
                    if let crurl = jsonCardReg["CardRegistrationURL"].string {
                        cardRegURL = URL(string: crurl)
                    }
                    
                    if let crd = jsonCardReg["Id"].string {
                        cardRegID = crd
                    }
                    
                    
                    // json
                    let walletIdData = JSON(returnedArray[1])
                    
                    if let walletID = walletIdData["walletID"].string {
                                        
                        let body = [
                            "accessKeyRef": accessKey,
                            "data": preregistrationData,
                            "cardNumber": self.cardNumberField,
                            "cardExpirationDate": self.expiryDateField,
                            "cardCvx": self.csvField
                            ]
                                                
                        // send card details to Mangopay's tokenization server, and get a RegistrationData object back as response
                        self.networkingClient.postCardInfo(url: cardRegURL, parameters: body) { (response, error) in
                            
                            if error != nil {
                                
                                self.removeSpinnerWithCompletion {
                                    self.universalShowAlert(title: "Something went wrong", message: "Nothing to worry about, the connection seems to have dropped. Please check your internet and try again. (If the problem persists, please contact support@wildfirewallet.com)", segue: nil, cancel: false)
                                }
                                return
                            }
                            
                            regData = String(response)

                            // now pass the RegistrationData object to callable Cloud Function which will complete the Card Registration and store the CardId in Firestore (this whole process is a secure way to store the user's card without having their sensitive info ever touch our server)
                            // N.B. we send the wallet ID received earlier so that the Cloud Function can store the final CardID under the user's Firestore wallet entry (the correct wallet - they could have multiple)
                            self.functions.httpsCallable("addCardRegistration").call(["regData": regData, "cardRegID": cardRegID, "walletID": walletID]) { (result, error) in

                                if let error = error {
                                    
                                    self.removeSpinnerWithCompletion {
                                        
                                        self.universalShowAlert(title: "Oops", message: "Something went wrong: \(error.localizedDescription)", segue: nil, cancel: false)
                                        // revive the button to prevent retries
                                        self.submitButton.isEnabled = true
                                    }
                                } else {
                                    
                                    Analytics.logEvent(Event.paymentMethodAdded.rawValue, parameters: [
                                        EventVar.paymentMethodAdded.paymentMethodType.rawValue: EventVar.paymentMethodAdded.paymentMethodTypeOptions.card.rawValue
                                    ])

//                                    self.submitButton.isEnabled = true
                                    
                                    let cardID = result?.data as! String

                                    // When the card has been added, trigger the API call to MangoPay to update UserDefaults with the card data (so that it shows up in the PaymentMethods View)
                                    // N.B. one benefit of NOT saving it directly is that MangoPay can handle any validation - this way, we only save it when it's definitely been correctly added to their MP account
                                    let appDelegate = AppDelegate()
                                    appDelegate.listCardsFromMangopay() { () in
                                        
                                        self.removeSpinnerWithCompletion {
                                            self.performSegue(withIdentifier: "showSuccessScreen", sender: self)
                                        }
                                    }

                                    // leaving makeDefault as true by default for now
                                    self.addAddressToCard(walletID: walletID, cardID: cardID, makeDefault: true)
                                }
                            }
                        }
                    }
                } else {
                    self.removeSpinnerWithCompletion {
                        // unlikely to be the connection in this case, instead
                        self.universalShowAlert(title: "Something went wrong", message: "This is an unusual one - sorry about this. All your details are secure and the tech team has been notified to look into the issue. Please allow 48 hours for this to be resolved. You can also contact us on support@wildfirewallet.com", segue: nil, cancel: false)
                        
                        Analytics.logEvent("improperCardInfoReturnedFromMangopay", parameters: nil)
                    }
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == countryTextField {
            return !autoCompleteText(in: textField, using: string, suggestions: self.countries)
        } else {
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
            case line1TextField: line2TextField.becomeFirstResponder()
            case line2TextField: cityTextField.becomeFirstResponder()
            case cityTextField: regionTextField.becomeFirstResponder()
            case regionTextField: postcodeTextField.becomeFirstResponder()
            case postcodeTextField: countryTextField.becomeFirstResponder()
            case countryTextField: countryTextField.resignFirstResponder()
            default: textField.resignFirstResponder()
        }
        
        return false
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
            
            guard let line1 = self.line1TextField.text else { return }
            // N.B. line2 is not required - if nothing entered then pass empty string
            let line2 = self.line2TextField.text ?? ""
            // "city" not key value coding-compliant - renamed to "cityName"
            guard let cityName = self.cityTextField.text else { return }
            guard let region = self.regionTextField.text else { return }
            guard let postcode = self.postcodeTextField.text else { return }
            // TODO country needs to be converted to appropriate format
            guard let country = self.countryTextField.text else { return }
            let countryCode = localeFinder(for: country)
            
            let addressData : [String: [String: String]] = [
                "billingAddress": ["line1": line1, "line2": line2,"city": cityName, "region": region,"postcode": postcode,"country": countryCode!]
            ]
            // separate variable name because that's how it shows up in Firestore
            let defaultAddressData : [String: Any] = [
                "defaultBillingAddress": ["line1": line1, "line2": line2,"city": cityName, "region": region,"postcode": postcode,"country": countryCode!], "defaultCardID": cardID
            ]
            
            // adding cardID to database here because cloud functions aren't working as expected and this is easier
            
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
        } else if localeFinder(for: country) == nil {
            return "Please re-enter country until autocorrect completes it"
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
    
    func showAlert(title: String?, message: String?, progress: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if progress == true {
                self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
            }
        }))
        self.present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
    }
            
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

