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
        
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "separator0Cell")!
            return cell
        } else if indexPath.row == 1 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "balanceCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        }
        else if indexPath.row == 2 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "userIDCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 3 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "separator1Cell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 4 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "receiptsCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 5 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "separator2Cell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 6 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "paymentMethodsCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 7 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "depositToBankCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 8 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "separator3Cell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else if indexPath.row == 9 {
             // User Profile Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "deleteAccountCell")!
//            let text = "cellText" //2.
//
//            cell.textLabel?.text = text //3.
            return cell
        } else {
             //configure cell type 2
            let cell = tableView.dequeueReusableCell(withIdentifier: "separator3Cell")!
            return cell
        }
    }
}
