//
//  AddCardSuccessViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 06/02/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

// N.B. this class is used in multiple places
// TODO might be worth renaming..? 
class AddCardSuccessViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleFilledButton(doneButton)
        
        // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
    self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
    self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false
        
        // generate haptic feedback onLoad to indicate usccess
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    

    @IBAction func doneButtonTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
}
