//
//  DisplayReceiptViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 16/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class DisplayReceiptAfterPaymentViewController: UIViewController {

    var transaction: Transaction?
    
    var isDynamicLinkResponder = false
  
    @IBOutlet weak var payerLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(doneButton)
        updateReceipt()
        
        // generate haptic feedback onLoad to indicate success
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
        
        if isDynamicLinkResponder == true {
            let label = UILabel()
            label.frame = CGRect(x: 20, y: 40, width: 300, height: 34)
            label.textAlignment = NSTextAlignment.left
            label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            label.text = "Payment Success"
            self.view.addSubview(label)
        }
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
    

    func updateReceipt() {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "HH:mm"
        
        payerLabel.text = transaction?.payerName
        recipientLabel.text = transaction?.recipientName
        if let x = transaction?.amount {
            let xFloat = Float(x)/100
            amountLabel.text = "£" + String(format: "%.2f", xFloat)
        }
        // TODO getting fatal error: unexpectedly found nil while unwrapping an optional value on line 54
        dateLabel.text = formatter.string(from: transaction!.datetime)
        timeLabel.text = formatter2.string(from: transaction!.datetime)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if self.isBeingPresented {
            self.dismiss(animated: true, completion: nil)
        
        } else {
            self.performSegue(withIdentifier: "unwindToPay", sender: self)
        }
    }
}

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
        
        Utilities.styleHollowButton(doneButton)
        updateReceipt()
    }
    

    func updateReceipt() {
        
        guard let transaction = transaction else {
            print("nil transaction")
            return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "HH:mm"
        
        payerLabel.text = transaction.payerName
        recipientLabel.text = transaction.recipientName
        
        let x = transaction.amount
        let xFloat = Float(x)/100
        amountLabel.text = "£" + String(format: "%.2f", xFloat)
        
        dateLabel.text = formatter.string(from: transaction.datetime)
        timeLabel.text = formatter2.string(from: transaction.datetime)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {

        self.dismiss(animated: true, completion: nil)
    }
}


