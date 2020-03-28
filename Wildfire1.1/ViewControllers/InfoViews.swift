//
//  Outcomes.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class OutcomeIDVerifiedViewController: UIViewController {

    var refusedMessage: String?
    
    @IBOutlet weak var okButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButton(okButton)
        
        // generate haptic feedback onLoad to indicate usccess
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    @IBAction func okTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

class OutcomeIDRefusedViewController: UIViewController {

    @IBOutlet weak var refusedReasonTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var newImageButton: UIButton!
    
    @IBOutlet weak var backToHomeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(newImageButton)
        Utilities.styleHollowButton(backToHomeButton)
        
        // generate haptic feedback onLoad to indicate usccess
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.error)
        
        
        if let refusedMessage = UserDefaults.standard.string(forKey: "refusedMessage") {
            if refusedMessage != "null" {
                refusedReasonTextView.text = refusedMessage
            } else {
                refusedReasonTextView.text = "No further reason or clarification was received. Please try again and ensure the image is readable and matches the name you provided."
            }
        } else {
            refusedReasonTextView.text = "No further reason or clarification was received. Please try again and ensure the image is readable and matches the name you provided."
        }
        if let type = UserDefaults.standard.string(forKey: "refusedType") {
            if type == "DOCUMENT_UNREADABLE" {
                titleLabel.text = "ID was unreadable"
            } else if type == "DOCUMENT_NOT_ACCEPTED" {
                titleLabel.text = "ID type is not accepted"
            } else if type == "DOCUMENT_HAS_EXPIRED" {
                titleLabel.text = "ID has expired"
            } else if type == "DOCUMENT_INCOMPLETE" {
                titleLabel.text = "ID is incomplete"
            } else if type == "DOCUMENT_MISSING" {
                titleLabel.text = "ID wasn't submitted"
            } else if type == "DOCUMENT_DO_NOT_MATCH_USER_DATA" {
                titleLabel.text = "ID does not match"
            } else if type == "DOCUMENT_DO_NOT_MATCH_ACCOUNT_DATA" {
                titleLabel.text = "ID does not match"
            } else if type == "SPECIFIC_CASE" {
                titleLabel.text = "ID refused"
            } else if type == "DOCUMENT_FALSIFIED" {
                titleLabel.text = "ID is not genuine"
            } else if type == "UNDERAGE_PERSON" {
                titleLabel.text = "User must be 18+"
            }
        }
        
        
    }
    
    @IBAction func newImageButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "retryKYC", sender: self)
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "KYCNavController") as! UINavigationController
//        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func backToHomeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

class CardLimitReached: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(doneButton)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
}
