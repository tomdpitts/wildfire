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
        
//        navigationItem.title = "Add Card"
//        navigationController?.navigationBar.prefersLargeTitles = true
        
        Utilities.styleTextField(cardNumberField)
        Utilities.styleTextField(expiryDateField)
        Utilities.styleTextField(csvField)
        Utilities.styleHollowButton(submitButton)
        
        // this is required for the limiting of text fields such as Card Number to only numeric values
        cardNumberField.delegate = self
        expiryDateField.delegate = self
        csvField.delegate = self
        
        errorLabel.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cardNumberField.becomeFirstResponder()
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        
        // API guide https://docs.mangopay.com/endpoints/v2.01/cards#e177_the-card-registration-object
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // This means there's something wrong with the fields, so show error message
            showError(error!)
        } else {
            performSegue(withIdentifier: "showAddCard2", sender: self)
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
            if expiryDate.count != 5 {
                return "Expiry Date should be in format MM/YY"
                }
            if csv.count != 3 {
                return "CSV number must be exactly 3 digits"
                }
        }
        
        let month = expiryDate.prefix(2)
        
        if let monthInt = Int(month) {
            if monthInt > 12 {
                return "Please enter a valid month (01 to 12)"
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yy"
        guard let enteredDate = dateFormatter.date(from: expiryDate) else { return nil }
        print(enteredDate)
        guard let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: enteredDate) else { return nil }
        print(endOfMonth)
        let now = Date()
        print(now)
        if (endOfMonth < now) {
            return "This card has expired"
        }
        
        return nil
    }
        
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
         if segue.destination is AddCard2TableViewController {
            let vc = segue.destination as! AddCard2TableViewController
            
            guard let cardNumber = cardNumberField.text, let expiry = expiryDateField.text, let csv = csvField.text else { return }
            
            // remove the slash from the MM/YY string to get MMYY (how Mangopay expects to receive it)
            let expiryFormatted = expiry.replacingOccurrences(of: "/", with: "")
            
            
            vc.cardNumberField = cardNumber
            vc.expiryDateField = expiryFormatted
            vc.csvField = csv
        }
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == cardNumberField {
            let allowedCharacters = CharacterSet(charactersIn:"0123456789 ")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        
        if textField == expiryDateField {
            
            // allow deletion
            if string == "" {
                return true
            }
            
            if let expiryMonth = expiryDateField.text {
                if expiryMonth.count == 2 {
                    let replacement = expiryMonth + "/" + string
                    expiryDateField.text = replacement
                    return false
                }
            }
        }
        
        return true
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
}
    
    

