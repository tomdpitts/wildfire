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
    
    @IBOutlet var noBankAccountsView: UIView!
    
    @IBOutlet weak var addAccountButton: UIButton!
    
    lazy var functions = Functions.functions(region:"europe-west1")
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    
    let cellID = "paymentMethodCell"
    var section = 0
    var row = 0
    var cardCount = 0
        
//            var transactionDates = [String]()
    var bankAccountsList = [BankAccount]()
//            var transactionsGrouped = [[Transaction]]()
        
        
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Bank Accounts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        fetchBankAccounts() { () in
//                if self.transactionsList.isEmpty == true {
//                    let title = "Looks like you haven't made any transactions yet"
//                    let message = "When you pay someone or get paid, it'll show up here"
//                    self.showAlert(title: title, message: message)
//                }
            self.tableView.reloadData()
            if self.bankAccountsList.count == 0 {
                self.tableView.addSubview(self.noBankAccountsView)
//                self.tableView.backgroundView = self.noBankAccountsView
                Utilities.styleHollowButton(self.addAccountButton)
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
        return bankAccountsList.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//            if indexPath.row == paymentMethodsList.count + 1 {
//                var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
//
//                cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
//
//                cell.textLabel?.text = "Add new card"
//
//                return cell
//
//            } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
                     
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
        
        if bankAccountsList.count == 0 {
            cell.textLabel?.text = "You haven't added any cards yet"
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
//            }

     
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
        
//        let storedCards = UserDefaults.standard.object(forKey: "storedCards") as? [PaymentCard] ?? [PaymentCard]()
//
//        self.paymentMethodsList = storedCards
        
        let defaults = UserDefaults.standard
        
        let count = defaults.integer(forKey: "numberOfBankAccounts")
        
        if count > 0 {
            for i in 1...count {
                
                guard let savedCardData = defaults.object(forKey: "bankAccount\(i)") as? Data else {
                    return
                }
                
                // Use PropertyListDecoder to convert retreived Data into PaymentCard
                guard let card = try? PropertyListDecoder().decode(BankAccount.self, from: savedCardData) else {
                    return
                }
                
                bankAccountsList.append(card)
            }
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
}

