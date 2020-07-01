//
//  AccountAddedViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 28/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class AccountAddedViewController: UIViewController {
    
    var userIsInPaymentFlow: Bool?

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var addCardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        Utilities.styleHollowButton(addCardButton)
        Utilities.styleHollowButtonRED(cancelButton)
        
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

    @IBAction func addCardTapped(_ sender: Any) {
        
        // Transition to step 2 aka PaymentSetUp VC
        self.performSegue(withIdentifier: "goToAddPayment", sender: self)
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        
        if self.userIsInPaymentFlow == true {
            
            showAlert(title: "Are you sure?", message: "Your payment can't be completed without card details. Tap 'Cancel' to go back and add them.", segue: "unwindToPay", cancel: true)
            
            
        } else {
            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is Account2ViewController {
            let vc = segue.destination as! Account2ViewController
            vc.justCompletedSignUp = true
        }
    }
    
    func showAlert(title: String, message: String?, segue: String?, cancel: Bool) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let seg = segue {
                    self.performSegue(withIdentifier: seg, sender: self)
                }
            }))

            if cancel == true {
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
            }
            
            self.present(alert, animated: true)
        }
    }

}
