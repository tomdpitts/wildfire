//
//  BankAccountsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 23/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Alamofire
import mangopay
import SwiftyJSON

class BankAccountsViewController: UITableViewController {
    
    @IBOutlet weak var addDetailsButton: UIBarButtonItem!
        
    lazy var functions = Functions.functions(region:"europe-west1")
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    
    let cellID = "paymentMethodCell"
    var section = 0
    var row = 0
    var cardCount = 0
        
    var bankAccountsList = [BankAccount]()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
//        fetchBankAccounts() { () in
//
//            if self.bankAccountsList.count > 0 {
//                self.addDetailsButton.isEnabled = false
//                self.addDetailsButton.tintColor = UIColor.clear
//
//            }
//            self.tableView.reloadData()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchBankAccounts() { () in

            self.tableView.reloadData()
        }
    }
    
    @objc func refresh(sender:AnyObject) {
        
        let appDelegate = AppDelegate()
        appDelegate.fetchBankAccountsListFromMangopay() { () in
            self.fetchBankAccounts {
                
                if self.bankAccountsList.count > 0 {
                    self.addDetailsButton.isEnabled = false
                    self.addDetailsButton.tintColor = UIColor.clear

                }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
//        override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//            let label = UILabel()
//            label.backgroundColor = UIColor(red: 218/255.0, green: 218/255.0, blue: 218/255.0, alpha: 1)
//            label.text = " " + transactionDates[section]
//            return label
//        }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // tableView needs to include a cell for each card, plus 1 cell for "Add new card"
        
        if bankAccountsList.count == 0 {
            return 1
        } else {
            return bankAccountsList.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
                 
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
        
        if bankAccountsList.count == 0 {
            cell.textLabel?.text = "Account details not yet added"
            cell.imageView?.image = UIImage(named: "icons8-bank-building-50")
        } else {
            let found = bankAccountsList[indexPath.row]
            if found.accountNumber != "" {
                cell.textLabel?.text = found.accountNumber
            } else if found.IBAN != "" {
                cell.textLabel?.text = found.IBAN
            } else {
                cell.textLabel?.text = "Registered Account \(indexPath.row)"
            }
            cell.imageView?.image = UIImage(named: "icons8-bank-building-50")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
        self.section = indexPath.section
        self.row = indexPath.row

        if bankAccountsList.count != 0 {
            performSegue(withIdentifier: "showBankDetails", sender: self)
        }
    }
        
    func fetchBankAccounts(completion: @escaping ()->()) {
        // TODO add mangopay call to fetch list of cards
        // OR store them locally?
        // UPDATE: decided to store in UserDefaults and have an API call in AppDelegate on AppDidEnterForeground to check the list is up to date in the background

//        self.paymentMethodsList = storedCards
        
        let defaults = UserDefaults.standard
        
        let count = defaults.integer(forKey: "numberOfBankAccounts")
        
        var list = [BankAccount]()
        
        if count > 0 {

            for i in 1...count {
                
                guard let savedCardData = defaults.object(forKey: "bankAccount\(i)") as? Data else {
                    return
                }
                
                // Use PropertyListDecoder to convert retreived Data into PaymentCard
                guard let card = try? PropertyListDecoder().decode(BankAccount.self, from: savedCardData) else {
                    return
                }
                list.append(card)
            }
        }
        
        bankAccountsList = list
        
        if self.bankAccountsList.count > 0 {
            self.addDetailsButton.isEnabled = false
            self.addDetailsButton.tintColor = UIColor.clear

        } else {
            self.addDetailsButton.isEnabled = true
            self.addDetailsButton.tintColor = UIColor(named: "tealPrimary")
        }
        
        completion()
    }
        
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let bdVC = segue.destination as? BankDetailViewController {
            let selectedAccount = bankAccountsList[self.row]
            bdVC.bankAccount = selectedAccount
        }
    }

    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}

