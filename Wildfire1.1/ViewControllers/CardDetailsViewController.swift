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
    
    var card = PaymentCard(cardNumber: "", cardProvider: "", expiryDate: "")

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        navigationItem.title = "Card Details"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    @IBAction func deleteCard(_ sender: Any) {
        
        
    }
    

    
}
