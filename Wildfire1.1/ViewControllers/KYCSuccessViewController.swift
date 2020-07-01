//
//  KYCSuccessViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 03/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

// N.B. this poorly-named VC is for the View that shows after KYC has been uploaded successfully! Not a dupe of KYCVerified

class KYCSuccessViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
    override func viewWillAppear(_ animated: Bool) {
        
        if self.doneButton != nil {
            Utilities.styleHollowButton(doneButton)
        }
        
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.setHidesBackButton(false, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        
        if self.isBeingPresented {
            self.dismiss(animated: true, completion: nil)
        
        } else {
            self.performSegue(withIdentifier: "unwindToAccountView", sender: self)
        }
    }
}
