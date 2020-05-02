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
    
    var paymentMethodsList = [PaymentCard]()
        
        
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchCardsFromUserDefaults() { () in
            self.tableView.reloadData()
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if paymentMethodsList.count == 0 {
//            return 1
//        } else {
//            return paymentMethodsList.count
//        }
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            var cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
                     
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: self.cellID)
        
        if paymentMethodsList.count == 0 {
            cell.textLabel?.text = "You haven't added any cards"
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
        } else {
            performSegue(withIdentifier: "showAddCardView", sender: self)
        }
    }
    
    @IBAction func addCardPressed(_ sender: Any) {
        
        if paymentMethodsList.count != 0 {
            performSegue(withIdentifier: "showCardLimitReachedView", sender: self)
        } else {
            performSegue(withIdentifier: "showAddCardView", sender: self)
        }
    }
    
    func fetchCardsFromUserDefaults(completion: @escaping ()->()) {
        
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
        } else {
            paymentMethodsList = []
        }
        completion()
    }
    
    @objc func refresh(sender:AnyObject) {
        
        let appDelegate = AppDelegate()
        appDelegate.listCardsFromMangopay() { () in
            self.fetchCardsFromUserDefaults {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
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
