//
//  PaymentSetupViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 19/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

import mangopay




class PaymentSetupViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegue(withIdentifier: "sendToAddCard", sender: self)
        
        // this screen might be useful in future when multiple payment types are supported, but for now we can pretend it's not there
    }

}

