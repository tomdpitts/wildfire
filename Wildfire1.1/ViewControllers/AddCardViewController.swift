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
        
        navigationItem.title = "Add Card"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // this is required for the limiting of text fields such as Card Number to only numeric values
        cardNumberField.delegate = self
        
        errorLabel.isHidden = true
        
    }
        
    // Not sure what this comment was about but I think it's no longer relevant. I think the Wallet creation used to happen prior to the card creation - that might have been it. Leaving as it might solve a mystery down the road:
    
    // watch out: theoretically the user can submit card details before this async function returns its values, which are required for the submitPressed func below. Leaving for time being as testing suggests it's practically impossible for user to fill in their card info that fast, but good to be aware
    
    
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
                
                print(result?.data)
                
                if let returnedArray = result?.data as? [[String: Any]] {
                // the result includes the bits we need (this is the result of step 4 in the diagram found at the API doc link above)
                    
                    print(returnedArray)
                    
                    
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
                        
                        print(walletID)
                    
                        semaphore.signal()
                    
                        let body = [
                            "accessKeyRef": accessKey,
                            "data": preregistrationData,
                            "cardNumber": self.cardNumberField.text!,
                            "cardExpirationDate": self.expiryDateField.text!,
                            "cardCvx": self.csvField.text!
                            ]
                        
                        print(body)
                        
                        // send card details to Mangopay's tokenization server, and get a RegistrationData object back as response
                        self.networkingClient.postCardInfo(url: cardRegURL, parameters: body) { (response, error) in
                            
                            if let err = error {
                                print(err)
                            }
                            print(response)
                            
                            
                            semaphore.wait()
                            
                            regData = String(response)
                            
                            semaphore.signal()
                            
                            print("checkpoint 1")

                            // now pass the RegistrationData object to callable Cloud Function which will complete the Card Registration and store the CardId in Firestore (this whole process is a secure way to store the user's card without having their sensitive info ever touch our server)
                            // N.B. we send the wallet ID received earlier so that the Cloud Function can store the final CardID under the user's Firestore wallet entry (the correct wallet - they could have multiple)
                            self.functions.httpsCallable("addCardRegistration").call(["regData": regData, "cardRegID": cardRegID, "walletID": walletID]) { (result, error) in

                                semaphore.wait()
                                //                if let error = error as NSError? {
                                //                    if error.domain == FunctionsErrorDomain {
                                //                        let code = FunctionsErrorCode(rawValue: error.code)
                                //                        let message = error.localizedDescription
                                //                        let details = error.userInfo[FunctionsErrorDetailsKey]
                                //                    }
                                // ...
                                //                }
                            
                                
                                
                                semaphore.signal()
                                
                                // When the card has been added, trigger the API call to MangoPay to update UserDefaults with the card data (so that it shows up in the PaymentMethods View)
                                // N.B. one benefit of NOT saving it directly is that MangoPay can handle any validation - this way, we only save it when it's definitely been correctly added to their MP account
                                let appDelegate = AppDelegate()
                                appDelegate.fetchPaymentMethodsListFromMangopay()
                                print("done?")
                                self.performSegue(withIdentifier: "unwindToPrevious", sender: self)

                            }
                            // TODO add loading spinner to wait for responseURL
                        }
                    }
                }
            }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // in the case that user is adding their card while in payment flow i.e. they came from ConfirmVC
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
            vc.shouldReloadView = true
        }
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
    
    

