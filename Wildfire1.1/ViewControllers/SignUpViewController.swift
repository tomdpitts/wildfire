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

class SignUpViewController: UIViewController {
    
    var loggedInUser = false
//    var handle: AuthStateDidChangeListenerHandle?
    var userIsInPaymentFlow = false

    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var lastName: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpElements()
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.destination is PaymentSetupViewController {
//            let vc = segue.destination as! PaymentSetupViewController
//
//        }
//    }
    
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
        errorLabel.alpha = 0
        
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
                let firstNameClean = firstName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                let lastNameClean = lastName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                let emailClean = email.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                let passwordClean = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Create the user
                Auth.auth().createUser(withEmail: emailClean, password: passwordClean) { (result, err) in
                    
                    // Check for errors
                    if err != nil {
                        
                        // There was an error creating the user
                        self.showError("Error creating user")
                    }
                    else {
                        
                        // User was created successfully, now store the first name and last name
                        let db = Firestore.firestore()
                        
                        
                        db.collection("users").document(result!.user.uid).setData(["firstname":firstNameClean, "lastname":lastNameClean, "email": emailClean, "balance": 0, "photoURL": "https://cdn.pixabay.com/photo/2014/05/21/20/17/icon-350228_1280.png" ]) { (error) in
                            
    //                        print(result!.user.uid)
                            if error != nil {
                                // Show error message
                                self.showError("Error saving user data")
                            }
                        }
                        
                    }
                    
                }
                    
            }
            
            if userIsInPaymentFlow == true {
                // Transition to step 2 aka PaymentSetUp VC
                self.performSegue(withIdentifier: "goToStep2", sender: self)
            } else {
                self.performSegue(withIdentifier: "unwindToAccountViewID", sender: self)
            }
            
        }
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    
    // this unwind is deliberately generic - provides an anchor for the 'back' button in Add Payment
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    
// Not sure the following function was ever a good idea - one to delete later
//    func transitionToHome() {
//
//        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
//
//        view.window?.rootViewController = homeViewController
//        view.window?.makeKeyAndVisible()
//
//    }
}
