//
//  CreditAddedSuccessViewController.swift
//  Wildfire1.1
//
//  Created by Tom Daniel on 15/04/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class CreditAddedSuccessViewController: UIViewController {
    
    var newBalance: Int?

    @IBOutlet weak var newBalanceLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButton(doneButton)
        
        // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
        self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
        
        if let newBalance = self.newBalance {
            let newBalanceFloat = Float(newBalance)/100
            let newBalanceString = String(format: "%.2f", newBalanceFloat)
            newBalanceLabel.text = "Your new balance is: £\(newBalanceString)"
        }
    }
}
