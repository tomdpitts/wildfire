//
//  CardDetailsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/01/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import Alamofire
import FirebaseFunctions
import FirebaseAnalytics

class CardDetailsViewController: UIViewController {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    @IBOutlet weak var cardNumberLabel: UILabel!
    
    @IBOutlet weak var expiryDateLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    
    var card: PaymentCard?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let crd = card {
            cardNumberLabel.text = crd.cardNumber
            
            // expiry date currently saved as 4 digit string i.e. MMYY. Let's separate out for a clearer look
            let month = crd.expiryDate.prefix(2)
            let year = crd.expiryDate.suffix(2)
            expiryDateLabel.text = month + "/" + year
        }
        
        Utilities.styleHollowButtonRED(deleteButton)
//
//        let red = UIColor(hexString: "#C63C39")
//        deleteButton.setTitleColor(red, for: UIControl.State.normal)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func deleteCardButtonTapped(_ sender: Any) {
        
        let title = "Delete Card"
        let message = "Are you sure you want to delete this card information? This cannot be undone."
        let segueID = "unwindToPrevious"
        
        showAlert(title: title, message: message, segueIdentifier: segueID)
    }
    
    
    func showAlert(title: String, message: String?, segueIdentifier: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            self.deleteCard() {
                self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true)
    }
    
    
    func deleteCard(completion: @escaping ()->()) {
        
        self.showSpinner(titleText: nil, messageText: nil)
        
        self.functions.httpsCallable("deleteCard").call() { (result, error) in
            // update credit cards list
            
            if error != nil {
                
                self.universalShowAlert(title: "Oops", message: "Something went wrong. Please try to delete the card again.", segue: nil, cancel: false)
            }
            
            Analytics.logEvent(Event.paymentMethodDeleted.rawValue, parameters: [
                EventVar.paymentMethodDeleted.paymentMethodType.rawValue: EventVar.paymentMethodDeleted.paymentMethodTypeOptions.card.rawValue
            ])

            
            let appDelegate = AppDelegate()
            appDelegate.listCardsFromMangopay() { () in
                self.removeSpinnerWithCompletion {
                    completion()
                }
            }
        }
        
        if let id = self.card?.cardID {
            UserDefaults.standard.removeObject(forKey: "card\(id)")
            let count = UserDefaults.standard.integer(forKey: "numberOfCards")
            if count > 0 {
                let newCount = count - 1
                UserDefaults.standard.set(newCount, forKey: "numberOfCards")
            }
        }
    }
    
}
