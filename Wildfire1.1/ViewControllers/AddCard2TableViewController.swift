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

class AddCard2TableViewController: UITableViewController {
    
    var cardNumberField: String?
    var expiryDateField: String?
    var csvField: String?
    
    @IBOutlet weak var line1: UITextField!
    @IBOutlet weak var line2: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var region: UITextField!
    @IBOutlet weak var postcode: UITextField!
    @IBOutlet weak var country: UITextField!
    
    
    
    
    
    
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Card Address Details"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
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
                                "cardNumber": self.cardNumberField,
                                "cardExpirationDate": self.expiryDateField,
                                "cardCvx": self.csvField
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
    
    func addAddressToCard(walletID: String, cardID: String, makeDefault: Bool, completion: @escaping (String) -> Void) {
        let validated = validateFields()
        
        if validated != "true" {
            errorLabel.text = validated
        } else {
            if let uid = Auth.auth().currentUser?.uid {
                
                Firestore.firestore().collection("users").document(uid).collection("wallets").document(walletID).collection("cards").document(cardID).setData(["address": {"line1": self.line1.textInputMode, "line2": self.line2,"city": city, "region": region,"postcode": postcode,"country": country}]
                // merge: true is IMPORTANT - prevents complete overwriting of a document if a user logs in for a second time, for example, which could wipe important data (including the balance..)
                , merge: true) { (error) in
                    // print(result!.user.uid)
                    if error != nil {
                        // Show error message
                        
                    } else {
                        
                        // progress: true presents next screen
                        self.showAlert(title: "Great! That's updated for you.", message: nil, progress: true)
                    }
                }
            }
        }
    }

        func validateFields() -> String {
            
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
        }
            
        func showError(_ message:String) {
            
            errorLabel.text = message
            errorLabel.isHidden = false
        }

}
