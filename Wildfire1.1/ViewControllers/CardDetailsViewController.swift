//
//  CardDetailsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/01/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import Alamofire

class CardDetailsViewController: UIViewController {
    
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
        
        let red = UIColor(hexString: "#C63C39")
        deleteButton.setTitleColor(red, for: UIControl.State.normal)
        
        
        
        
        navigationItem.title = "Card Details"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    @IBAction func deleteCard(_ sender: Any) {
        
        
    }
    
//
//    func showAlert(title: String, message: String?, segueIdentifier: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
//            do {
//                try Auth.auth().signOut()
//                // update the userAccountExists flag (if user signs in with a different number, we don't want this flag to persist in memory and mess things up
//                UserDefaults.standard.set(false, forKey: "userAccountExists")
//            } catch let err {
//                // TODO what if signout fails e.g. no connection
//            }
//            self.performSegue(withIdentifier: segueIdentifier, sender: self)
//        }))
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//        }))
//        
//        self.present(alert, animated: true)
//    }
    
}
