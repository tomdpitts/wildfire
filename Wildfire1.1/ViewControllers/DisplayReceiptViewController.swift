//
//  DisplayReceiptViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 16/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class DisplayReceiptViewController: UIViewController {

    var transaction: Transaction? = nil
    
    @IBOutlet weak var payerLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Receipt"
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
        
        dateLabel.text = formatter.string(from: transaction!.datetime)
        timeLabel.text = formatter2.string(from: transaction!.datetime)
    }

}
