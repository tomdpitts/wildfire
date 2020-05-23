//
//  BankAccountAddedViewController.swift
//  Wildfire
//
//  Created by Tom Daniel on 01/05/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class BankAccountAddedViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(doneButton)
        
        // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.setHidesBackButton(false, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}
