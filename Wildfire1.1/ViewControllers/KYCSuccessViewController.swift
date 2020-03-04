//
//  KYCSuccessViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 03/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class KYCSuccessViewController: UIViewController {
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var alrightButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let done = self.doneButton {
            Utilities.styleHollowButton(doneButton)
        }
        
        if let cont = self.continueButton {
            Utilities.styleHollowButton(continueButton)
        }
        
        if let alright = self.alrightButton {
            Utilities.styleHollowButton(alrightButton)
        }
    }
}
