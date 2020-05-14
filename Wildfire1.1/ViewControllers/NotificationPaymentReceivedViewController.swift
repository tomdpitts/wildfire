//
//  NotificationPaymentReceivedViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 20/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class NotificationPaymentReceivedViewController: UIViewController {
    
    var authorName: String = ""
    var currency: String = ""
    var amount: String = ""

    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(Event.receivedSuccess.rawValue, parameters: [
            EventVar.receivedSuccess.receivedAmount.rawValue: amount,
            EventVar.receivedSuccess.currency.rawValue: currency
        ])
        
        
        amountLabel.text = currency + amount
        nameLabel.text = authorName
        
        Utilities.styleHollowButton(doneButton)
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
