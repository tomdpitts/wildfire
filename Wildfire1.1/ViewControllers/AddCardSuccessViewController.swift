//
//  AddCardSuccessViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 06/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class AddCardSuccessViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleFilledButton(doneButton)
        
    }
    

    @IBAction func doneButtonTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // in the case that user is adding their card while in payment flow i.e. they came from ConfirmVC
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
            vc.shouldReloadView = true
        }
    }

}
