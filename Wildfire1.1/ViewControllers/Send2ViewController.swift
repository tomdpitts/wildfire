//
//  Send2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 18/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class Send2ViewController: UIViewController {


    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    
    
    var contact: Contact?
    var transaction: Transaction?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        amountTextField.becomeFirstResponder()
        if let contact = contact {
            recipientLabel.text = contact.fullName
        }
    }
    
    
}
