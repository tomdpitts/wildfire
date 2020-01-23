//
//  formStep2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 15/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class formStep2ViewController: UIViewController {

    var userIsInPaymentFlow = false
    
    var firstname = ""
    var lastname = ""
    var email = ""
//    var password = ""
    
    @IBOutlet weak var dobPicker: UIDatePicker!
    var dob: Int64?
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        navigationItem.title = "Date of Birth"
        navigationController?.navigationBar.prefersLargeTitles = true
        

        setUpElements()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is formStep3ViewController {
            let vc = segue.destination as! formStep3ViewController
            vc.userIsInPaymentFlow = userIsInPaymentFlow
            vc.firstname = firstname
            vc.lastname = lastname
            vc.email = email
//            vc.password = password
            vc.dob = dob
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        dob = dobPicker.date.toSeconds()
        if dob == nil {
            showError("Please enter a valid Date of Birth")
        } else {
            performSegue(withIdentifier: "goToFormStep3", sender: self)
        }
    }
    
    func setUpElements() {
            
        // Hide the error label
        errorLabel.isHidden = true
        
        dobPicker.minimumDate = Calendar.current.date(byAdding: .year, value: -150, to: Date())
        dobPicker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        
        // Style the elements
        Utilities.styleFilledButton(nextButton)
        }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}
