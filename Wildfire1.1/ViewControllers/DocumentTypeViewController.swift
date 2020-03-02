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
    }
}
