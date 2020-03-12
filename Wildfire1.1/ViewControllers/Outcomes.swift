//
//  Outcomes.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit

class OutcomeIDVerifiedViewController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.styleHollowButton(okButton)
    }
    
    @IBAction func okTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "accountNavController") as! UINavigationController
        self.present(vc, animated: true, completion: nil)
    }
    
}

class OutcomeIDRefusedViewController: UIViewController {

    @IBOutlet weak var refusedReasonTextView: UITextView!
    
    @IBOutlet weak var newImageButton: UIButton!
    
    @IBOutlet weak var backToHomeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(newImageButton)
        Utilities.styleHollowButton(backToHomeButton)
    }
    
    @IBAction func newImageButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "KYCNavController") as! UINavigationController
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func backToHomeButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "accountNavController") as! UINavigationController
        self.present(vc, animated: true, completion: nil)
    }
}
