//
//  AddCardViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 30/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import Alamofire
import SwiftyJSON

// UITextFieldDelegate added to class for tidy text field validation (https://stackoverflow.com/questions/30973044/how-to-restrict-uitextfield-to-take-only-numbers-in-swift/44441195)

class AddCardViewController: UIViewController, UITextFieldDelegate {
    
    private let networkingClient = NetworkingClient()
    lazy var functions = Functions.functions(region:"europe-west1")

    @IBOutlet weak var cardNumberField: UITextField!
    
    @IBOutlet weak var expiryDateField: UITextField!
    
    @IBOutlet weak var csvField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // this is required for the limiting of text fields such as Card Number to only numeric values
        cardNumberField.delegate = self
        
        errorLabel.isHidden = true
        
        cardNumberField.isHidden = true
        expiryDateField.isHidden = true
        csvField.isHidden = true
        submitButton.isHidden = true
        
        
        cardNumberField.isEnabled = false
        expiryDateField.isEnabled = false
        csvField.isEnabled = false
        submitButton.isEnabled = false
    }
    
    
    
    
    @IBAction func addCard(_ sender: Any) {
        
        cardNumberField.isHidden = false
        expiryDateField.isHidden = false
        csvField.isHidden = false
        submitButton.isHidden = false
        
        cardNumberField.isEnabled = true
        expiryDateField.isEnabled = true
        csvField.isEnabled = true
        submitButton.isEnabled = true
        
            // watch out: theoretically the user can submit card details before this async function returns its values, which are required for the submitPressed func below. Leaving for time being as testing suggests it's practically impossible for user to fill in their card info that fast, but good to be aware
        }
    
    
    @IBAction func submitPressed(_ sender: Any) {
        
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
        } else {
            
            var accessKey = ""
            var preregistrationData = ""
            var cardRegURL: URL!
            var cardRegID = ""
            var regData = ""
            
            // Semaphore is used to ensure async API calls aren't triggered before all the relevant data is ready - they have to be sequential
            let semaphore = DispatchSemaphore(value: 1)
            
            // fields have passed validation - so continue
            functions.httpsCallable("createPaymentMethodHTTPS").call(["text": "Euros"]) { (result, error) in
//                if let error = error as NSError? {
//                    if error.domain == FunctionsErrorDomain {
//                        let code = FunctionsErrorCode(rawValue: error.code)
//                        let message = error.localizedDescription
//                        let details = error.userInfo[FunctionsErrorDetailsKey]
//                    }
//                    // ...
//                }
                semaphore.wait()
                
                let json = JSON(result?.data ?? "no data returned")
                
                // extract the following values from the returned CardRegistration object
                if let ak = json["AccessKey"].string {
                    accessKey = ak
                }
                
                if let prd = json["PreregistrationData"].string {
                    preregistrationData = prd
                }
                
                if let crurl = json["CardRegistrationURL"].string {
                    cardRegURL = URL(string: crurl)
                }
                
                if let crd = json["Id"].string {
                    cardRegID = crd
                }
                

                semaphore.signal()
            
                let body = [
                    "accessKeyRef": accessKey,
                    "data": preregistrationData,
                    "cardNumber": self.cardNumberField.text!,
                    "cardExpirationDate": self.expiryDateField.text!,
                    "cardCvx": self.csvField.text!
                    ]
                
                // send card details to Mangopay's tokenization server, and get a RegistrationData object back as response
                self.networkingClient.postCardInfo(url: cardRegURL, parameters: body) { (response, error) in
                    
                    semaphore.wait()
                    
                    regData = String(response)
                    
                    semaphore.signal()

                    // now pass the RegistrationData object to callable Cloud Function which will complete the Card Registration and store the CardId in Firestore (this whole process is a secure way to store the user's card without having their sensitive info ever touch our server)
                    self.functions.httpsCallable("addCardRegistration").call(["regData": regData, "cardRegID": cardRegID]) { (result, error) in

                        semaphore.wait()
                        //                if let error = error as NSError? {
                        //                    if error.domain == FunctionsErrorDomain {
                        //                        let code = FunctionsErrorCode(rawValue: error.code)
                        //                        let message = error.localizedDescription
                        //                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        //                    }
                        // ...
                        //                }
                        
                        let json = JSON(result?.data ?? "no data returned")
                        
                        
                        print("done?")
                        semaphore.signal()

                    }
                    
                    // TODO add loading spinner to wait for responseURL

                }
            }
        }
    }
    
    func saveCardStubToDisk() {
        
        functions.httpsCallable("listCards").call() { (result, error) in
            
            let json = JSON(result?.data ?? "no data returned")

            print(json)
        }
    }
    
    func fetchPaymentMethodsListFromMangopay() {
        functions.httpsCallable("listCards").call() { (result, error) in
            var cardNumberStub = ""
            
            let jsonArray = JSON(result?.data ?? "no data returned")
            
            // data is returned as array of json blobs - don't forget a user can have multiple cards so this makes sense.
            // TODO parse the result and save to UserDefaults (?), or alternatively, fetch the data each time the page is loaded, but that feels like a bad solution. It might be MVP worthy though.
            
            // extract the following values from the returned CardRegistration object
            if let alias = jsonArray["Alias"].string {
                cardNumberStub = alias
                print(cardNumberStub)
            } else {
                print("no alias")
            }

            print(jsonArray)
            
        }
    }

    
    
    func validateFields() -> String? {
        
        let cardNumber = cardNumberField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let expiryDate = expiryDateField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let csv = csvField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        // Check that all fields are filled in
        if cardNumber == "" ||
            expiryDate == "" ||
            csv == ""
            {
            return "Please fill in all fields."
            
        } else {
    
            if cardNumber.count != 16 {
                return "Card Number must be 16 digits long"
                }
            if expiryDate.count != 4 {
                return "Expiry Date should be in format MMYY"
                }
            if csv.count != 3 {
                return "CSV number must be exactly 3 digits"
                }
            }
            return nil
        }
        
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
        
    //MARK - UITextField Delegates
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == cardNumberField {
            let allowedCharacters = CharacterSet(charactersIn:"0123456789")//Here change this characters based on your requirement
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
    
    

