//
//  ConfirmViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class ConfirmViewController: UIViewController {
    
    var readStringConfirm = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        QROutput.text = readStringConfirm
        

        // Do any additional setup after loading the view.
    }
    

    @IBOutlet weak var QROutput: UILabel!
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
