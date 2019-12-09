//
//  Account2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class Account2ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Account"
        navigationController?.navigationBar.prefersLargeTitles = true

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, cellText: String) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")! //1.
            
         let text = cellText //2.
            
         cell.textLabel?.text = text //3.
            
         return cell //4.
    }

}
