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
        
        Utilities.styleHollowButton(doneButton)
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    // this screen should be loaded in the stack as usual so that unwindToPrevious works correctly i.e. the exit segue is context-dependant as we want it to be. But we don't want the user to go back to the last screen having just successfully submitted their billing address and card details etc.
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

    @IBAction func doneButtonTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
            vc.shouldReloadView = true
        }
    }
}

class CardMiscInfoViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(doneButton)
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
}

class MultipleCardsViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
    super.viewDidLoad()
        Utilities.styleHollowButton(doneButton)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
}

