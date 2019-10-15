//
//  formStep2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 15/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class formStep2ViewController: UIViewController {

    @IBOutlet weak var dobPicker: UIDatePicker!
    var dob: Date?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dobPicker.minimumDate = Calendar.current.date(byAdding: .year, value: -150, to: Date())
        dobPicker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())

    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        dob = dobPicker.date
        performSegue(withIdentifier: "formStep3Segue", sender: self)
    }
    
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
}
