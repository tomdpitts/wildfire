//
//  SignUpViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 26/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    var loggedInUser = false
//    var handle: AuthStateDidChangeListenerHandle?
    var userIsInPaymentFlow = false

    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var lastName: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    var firstnameClean = ""
    var lastnameClean = ""
    var emailClean = ""
    var passwordClean = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        // Do any additional setup after loading the view.
        setUpElements()
        
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is formStep2ViewController {
            let vc = segue.destination as! formStep2ViewController
            vc.userIsInPaymentFlow = userIsInPaymentFlow
            vc.firstname = firstnameClean
            vc.lastname = lastnameClean
            vc.email = emailClean
            vc.password = passwordClean
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
            signUpTapped(self)
        }
        return true
    }
    
     // for time being, leave this out as it's causing an issue because I'm always logged in
//
//    override func viewWillAppear(_ animated: Bool) {
//        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
//
//
//            if (Auth.auth().currentUser?.uid) != nil {
//                self.loggedInUser = true
//            } else {
//                self.loggedInUser = false
//            }
//
//
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        Auth.auth().removeStateDidChangeListener(handle!)
//    }
    
    func setUpElements() {
        
        // Hide the error label
        errorLabel.isHidden = true
        
        // Style the elements
        Utilities.styleTextField(firstName)
        Utilities.styleTextField(lastName)
        Utilities.styleTextField(email)
        Utilities.styleTextField(password)
        Utilities.styleFilledButton(signUpButton)
    }
    
    // Check the fields and validate. If everything kosher, this func returns nil, otherwise it returns the error message
    func validateFields() -> String? {
        
        // Check that all fields are filled in
        if firstName.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastName.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            email.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            password.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "Please fill in all fields."
        }
        
        // Check if the password is secure
        let cleanedPassword = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if Utilities.isPasswordValid(cleanedPassword) == false {
            // Password isn't secure enough
            return "Please make sure your password is at least 8 characters and contains a number."
        }
        
        return nil
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // There's something wrong with the fields, show error message
            showError(error!)
        } else {
            
            if loggedInUser == false {
                    
                // Create cleaned versions of the data
                self.firstnameClean = firstName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                self.lastnameClean = lastName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                self.emailClean = email.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                self.passwordClean = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    
            }
            self.performSegue(withIdentifier: "goToFormStep2", sender: self)
        }
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    // this unwind is deliberately generic - provides an anchor for the 'back' button in Add Payment
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
}
