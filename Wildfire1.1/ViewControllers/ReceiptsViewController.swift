//
//  ReceiptsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

//class ReceiptCell: UITableViewCell {
//
//
//    @IBOutlet weak var nameLabel: UILabel!
//
//    @IBOutlet weak var amountLabel: UILabel!
//
//}

class ReceiptsViewController: UITableViewController {
    
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    
    let cellID = "receiptCell"
        
//        var names = [String]()
//        var namesList = [[String]]()
//        var contactsList = [Contact]()
//        var contactsGrouped = [[Contact]]()
//
//        var phonebook = [String: String]()
//        var namesDict = [[String: String]]()
    var section = 0
    var row = 0
    var selectedTransaction: Transaction?
    
    // dictionaries are unordered, arrays play nicer w Tableview
    var transactionDates = [String]()
    var transactionsList = [Transaction]()
    var transactionsGrouped = [[Transaction]]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        transactionDates = []
        transactionsList = []
        transactionsGrouped = []
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
//        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        
        fetchTransactions() { () in
            if self.transactionsList.isEmpty == true {
                let title = "Looks like you haven't made any transactions yet"
                let message = "When you pay someone or get paid, it'll show up here"
                self.showAlert(title: title, message: message)
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 218/255.0, green: 218/255.0, blue: 218/255.0, alpha: 1)
        label.text = " " + transactionDates[section]
        return label
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactionsGrouped[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return transactionDates.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
        
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
        
        let found = transactionsGrouped[indexPath.section][indexPath.row]
        
        // we want the other party's name as the label
        if found.payerID == uid {
            // the user was the payer, so the label should detail the other party's name
            cell.textLabel?.text = found.recipientName
            cell.imageView?.image = UIImage(named: "icons8-brick-paper-plane-50")
        } else {
            cell.textLabel?.text = found.payerName
            cell.imageView?.image = UIImage(named: "icons8-teal-get-cash-50")
        }
        let amount = String(format: "%.2f", Float(found.amount)/100)
        cell.detailTextLabel?.text = String(amount)
        
        
        return cell
    }
    
    func fetchTransactions(completion: @escaping ()->()) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        
        
        if let uid = uid {
            db.collection("users").document(uid).collection("receipts").order(by: "datetime", descending: true).addSnapshotListener { querySnapshot, error in
                
                guard (querySnapshot?.documents) != nil else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                var transactionDates = [String]()
                var transactionsList = [Transaction]()
                var transactionsGrouped = [[Transaction]]()
                
                for document in querySnapshot!.documents {
                    
                    
                    let data = document.data()
                    let amount = data["amount"] as! Int
                    let datetimeUNIX = data["datetime"] as! Int
                    let datetime = Date(timeIntervalSince1970: TimeInterval(datetimeUNIX))
                    let formattedDatetime = formatter.string(from: datetime)
                    
                    let currency = data["currency"] as! String
                    
                    let payerID = data["payerID"] as! String
                    let recipientID = data["recipientID"] as! String
                    
                    let payerName = data["payerName"] as! String
                    let recipientName = data["recipientName"] as! String
                    
                    let userIsPayer = data["userIsPayer"] as! Bool
                    
                    
                    let transactionData = Transaction(amount: amount, currency: currency, datetime: datetime, payerID: payerID, recipientID: recipientID, payerName: payerName, recipientName: recipientName, userIsPayer: userIsPayer)
                    
                    transactionsList.append(transactionData)
                    
                    
                    if transactionDates.contains(where: {$0 == formattedDatetime}) {
                       // it exists, do nothing
                    } else {
                       //item could not be found, so let's add it
                        transactionDates.append(formattedDatetime)
                    }
                }
                
                
                    
                // sorting the Transactions into groups by transaction date
                for x in transactionDates {
                   var group: [Transaction] = []
                    for i in transactionsList {
                        // transactions have datetime saved as Date, but we need to compare them to the String/formatted date labels
                        // N.B. since the original data request is ordered by date, there shouldn't be any need for further ordering by time
                        let j = i.datetime
                        let m = formatter.string(from: j)
                        if m == x {
                            group.append(i)
                        }
                   }
                       transactionsGrouped.append(group)
                   }
                
                // we've just been adding these transactions to local arrays, now need to update the class variables to allow the tableview to refresh with the right data
                self.transactionDates = transactionDates
                self.transactionsList = transactionsList
                self.transactionsGrouped = transactionsGrouped
                
                self.tableView.reloadData()
                
                completion()
            }
        }
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedTransaction = transactionsGrouped[indexPath.section][indexPath.row]
        print(selectedTransaction)
//        self.section = indexPath.section
//        self.row = indexPath.row

        
        performSegue(withIdentifier: "displayReceipt", sender: self)
    }
    
//    @objc func refresh(sender:AnyObject) {
//
//        fetchTransactions() { () in
//            self.tableView.reloadData()
//        }
//    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DisplayReceiptViewController {
            if let displayReceiptVC = segue.destination as? DisplayReceiptViewController {
                
                displayReceiptVC.transaction = self.selectedTransaction
            }
            
        }
    }
    
    
    
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
}


