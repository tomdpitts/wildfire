//
//  TermsViewController.swift
//  Wildfire
//
//  Created by Tom Daniel on 20/04/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class TermsViewController: UIViewController {

    @IBOutlet weak var privacySwitch: UISwitch!
    
    @IBOutlet weak var termsSwitch: UISwitch!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButton(doneButton)
        
        errorLabel.isHidden = true
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        let privacy = privacySwitch.isOn
        let terms = termsSwitch.isOn
        
        if privacy == true || terms == true {
            performSegue(withIdentifier: "unwindToWelcome", sender: self)
            
        } else {
            errorLabel.text = "Please accept both agreements"
            errorLabel.isHidden = false
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
