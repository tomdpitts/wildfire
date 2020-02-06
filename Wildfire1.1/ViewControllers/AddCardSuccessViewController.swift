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
        
        // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
        self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false;
        
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
