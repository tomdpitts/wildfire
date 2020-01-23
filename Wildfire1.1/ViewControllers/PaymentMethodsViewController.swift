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
import FirebaseFunctions
import Alamofire
import mangopay
import SwiftyJSON

class PaymentMethodsViewController: UITableViewController {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    
    let cellID = "paymentMethodCell"
    var section = 0
    var row = 0
    var cardCount = 0
        
//            var transactionDates = [String]()
    var paymentMethodsList = [PaymentCard]()
//            var transactionsGrouped = [[Transaction]]()
        
        
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Payment Methods"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        fetchCards() { () in
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
        // tableView needs to include a cell for each card, plus 1 cell for "Add new card"
        if paymentMethodsList.count == 0 {
            return 1
        } else {
            return paymentMethodsList.count
        }
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
        
        if paymentMethodsList.count == 0 {
            cell.textLabel?.text = "You haven't added any cards yet"
            cell.imageView?.image = UIImage(named: "icons8-mastercard-credit-card-50")
        } else {
            let found = paymentMethodsList[indexPath.row]
             
                cell.textLabel?.text = found.cardNumber
            cell.imageView?.image = UIImage(named: "icons8-mastercard-credit-card-50")
        }
            return cell
//            }

     
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
        self.section = indexPath.section
        self.row = indexPath.row

        if paymentMethodsList.count != 0 {
            performSegue(withIdentifier: "showCardDetails", sender: self)
        }
    }
        
    func fetchCards(completion: @escaping ()->()) {
        // TODO add mangopay call to fetch list of cards
        // OR store them locally?
        // UPDATE: decided to store in UserDefaults and have an API call in AppDelegate on AppDidEnterForeground to check the list is up to date in the background
        
//        let storedCards = UserDefaults.standard.object(forKey: "storedCards") as? [PaymentCard] ?? [PaymentCard]()
//
//        self.paymentMethodsList = storedCards
        
        let defaults = UserDefaults.standard
        
        let count = defaults.integer(forKey: "numberOfCards")
        
        if count > 0 {
            for i in 1...count {
                
                guard let savedCardData = defaults.object(forKey: "card\(i)") as? Data else {
                    return
                }
                
                // Use PropertyListDecoder to convert retreived Data into PaymentCard
                guard let card = try? PropertyListDecoder().decode(PaymentCard.self, from: savedCardData) else {
                    return
                }
                
                paymentMethodsList.append(card)
            }
        }
        
        completion()
    }
        
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let showCardDetailsVC = segue.destination as? CardDetailsViewController {
            let selectedCard = paymentMethodsList[self.row]
            showCardDetailsVC.card = selectedCard
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
