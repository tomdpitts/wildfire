//
//  DisplayReceiptViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 16/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class DisplayReceiptViewController: UIViewController {

    var transaction: Transaction?
    
    @IBOutlet weak var payerLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Receipt"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
    self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false;
    self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false
        
        Utilities.styleHollowButton(doneButton)
        updateReceipt()
    }
    

    func updateReceipt() {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "HH:mm"
        
        payerLabel.text = transaction?.payerName
        recipientLabel.text = transaction?.recipientName
        if let x = transaction?.amount {
            let xFloat = Float(x)/100
            amountLabel.text = String(format: "%.2f", xFloat)
        }
        // TODO getting fatal error: unexpectedly found nil while unwrapping an optional value on line 54
        print(transaction?.datetime)
        dateLabel.text = formatter.string(from: transaction!.datetime)
        timeLabel.text = formatter2.string(from: transaction!.datetime)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
