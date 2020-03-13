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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
    self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
    self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.doneButton != nil {
            Utilities.styleHollowButton(doneButton)
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        
        if self.isBeingPresented {
            self.dismiss(animated: true, completion: nil)
        
        } else {
            self.performSegue(withIdentifier: "unwindToAccountView", sender: self)
        }
        
        
    }
}
