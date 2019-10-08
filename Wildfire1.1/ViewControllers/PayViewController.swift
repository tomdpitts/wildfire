//
//  PayViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class PayViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func unwindToPay(_ unwindSegue: UIStoryboardSegue) {
        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
//    // This next bit is supposed to stop the dang thing rotating in landscape mode, but doesn't seem to work
//    override open var shouldAutorotate: Bool {
//        return false
//    }
//
    @IBAction func launchQRReader(_ sender: UIButton) {

    // the QR code needs to go here?
    }

//    @IBAction func unwindToPayViewController(segue: UIStoryboardSegue) {
//    }
//    
}

