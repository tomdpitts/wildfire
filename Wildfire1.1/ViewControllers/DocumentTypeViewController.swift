//
//  DocumentTypeViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class DocumentTypeViewController: UIViewController {
    
    
    @IBOutlet weak var passportButton: UIButton!
    @IBOutlet weak var driverLicenceButton: UIButton!
    @IBOutlet weak var IDCard: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButton(passportButton)
        Utilities.styleHollowButton(driverLicenceButton)
        Utilities.styleHollowButton(IDCard)
        
        // to guard against edge case where user creates an account and immediately tries to deposit funds - they'll need mangopayID stored in UserDefaults
        if UserDefaults.standard.string(forKey: "mangopayID") == nil {
            Utilities().getMangopayID()
        }
    }
}
