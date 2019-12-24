//
//  PaymentMethodsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 23/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Alamofire
import mangopay

class PaymentMethodsViewController: UITableViewController {
        
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid
        
        let cellID = "paymentMethodCell"
        var section = 0
        var row = 0
        
//            var transactionDates = [String]()
        var paymentMethodsList = [PaymentMethod]()
//            var transactionsGrouped = [[Transaction]]()
        
        
            
        override func viewDidLoad() {
            super.viewDidLoad()
            
            navigationItem.title = "Payment Methods"
            navigationController?.navigationBar.prefersLargeTitles = true
            
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
            
            fetchTransactions() { () in
//                if self.transactionsList.isEmpty == true {
//                    let title = "Looks like you haven't made any transactions yet"
//                    let message = "When you pay someone or get paid, it'll show up here"
//                    self.showAlert(title: title, message: message)
//                }
                self.tableView.reloadData()
            }
            
        }
        
//        override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//            let label = UILabel()
//            label.backgroundColor = UIColor(red: 218/255.0, green: 218/255.0, blue: 218/255.0, alpha: 1)
//            label.text = " " + transactionDates[section]
//            return label
//        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return paymentMethodsList.count
        }
        
        override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
            
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
            
            let found = paymentMethodsList[indexPath.row]
            
            cell.textLabel?.text = found.name
            cell.detailTextLabel?.text = found.truncatedCardNumber
            cell.imageView?.image = found.icon
            
            return cell
        }
        
        func fetchTransactions(completion: @escaping ()->()) {
            // TODO add mangopay call to fetch list of cards
            // OR store them locally?
            let cardsEndpoint =
            
            if let photoURL = photoURL {
                Alamofire.request(photoURL).responseData(completionHandler: { (response) in
                    if let data = response.value {
                        let image = UIImage(data: data)
                        // upload of the profilePic is handled automatically on change of the self.profilePic variable by uploadProfilePic func
                        self.profilePic = image
                    }
                })
            }
            completion()
        }
            
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // without this line, the cell remains (visually) selected after end of tap
            tableView.deselectRow(at: indexPath, animated: true)
            self.section = indexPath.section
            self.row = indexPath.row

            
            performSegue(withIdentifier: "displayReceipt", sender: self)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            if let displayReceiptVC = segue.destination as? DisplayReceiptViewController {
                let selectedTransaction = transactionsGrouped[self.section][self.row]
                displayReceiptVC.transaction = selectedTransaction
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
        }

}
