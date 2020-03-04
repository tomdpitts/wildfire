//
//  ButtonStyleViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 04/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class ButtonStyleViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var alrightButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    override func viewWillAppear(_ animated: Bool) {
        if self.continueButton != nil {
            Utilities.styleHollowButton(continueButton)
        }
        
        if self.alrightButton != nil {
            Utilities.styleHollowButton(alrightButton)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
