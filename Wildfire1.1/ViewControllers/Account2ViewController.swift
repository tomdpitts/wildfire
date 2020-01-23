//
//  Account2ViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/12/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class Account2ViewController: UITableViewController {
    var genericProfilePic = UIImage(named: "icons8-user-50")
    var balance: Int?
    var firstname: String?
    var lastname: String?
    var email: String?
    var profilePic: UIImage?

    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balanceAmountLabel: UILabel!
    
    @IBOutlet weak var logOutCell: UITableViewCell!
    
    @IBOutlet weak var noAccountYetCell: UITableViewCell!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        
        if UserDefaults.standard.bool(forKey: "userAccountExists") == true {
            getUserInfo()
            setUpProfilePic()
        }
        
        navigationItem.title = "Account"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        // we only need this cell if there's no account yet
        if UserDefaults.standard.bool(forKey: "userAccountExists") == true {
            noAccountYetCell.isHidden = true
        }
        

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if UserDefaults.standard.bool(forKey: "userAccountExists") == false {
             return 2
        } else {
            return 11
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 9 {
            let title = "Are you sure you want to Log Out?"
            let message = "You can log back in at any time"
            let segue = "goToPhoneVerify"
            showAlert(title: title, message: message, segueIdentifier: segue)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getUserInfo() {
        if let uid = Auth.auth().currentUser?.uid {
            let docRef = Firestore.firestore().collection("users").document(uid)

            docRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                
                    print("Error fetching document: \(error!)")
                    return
                }
                
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                
                let balance = data["balance"] as! Int
                let balanceString = String(balance)
                let firstname = data["firstname"] as! String
                let lastname = data["lastname"] as! String
                let email = data["email"] as! String
                
                self.email = email
                self.firstname = firstname
                self.lastname = lastname
                
                self.userNameLabel.text = firstname + " " + lastname
                self.balanceAmountLabel.text = balanceString
              }
        }
    }
         //     TO BE DELETED:
    
//            // TODO replace with listener
//            docRef.getDocument { (document, error) in
//                if let error = error {
//                    // TODO error handling
//                    print(error)
//                } else {
//                }
//                if let document = document, document.exists {
//                    let userData = document.data()
//                    let balance = userData?["balance"] as! Int
//                    let balanceString = String(balance)
//                    let firstname = userData?["firstname"] as! String
//                    let lastname = userData?["lastname"] as! String
//
//                    self.balance = balance
//                    self.firstname = firstname
//                    self.lastname = lastname
//
//                    self.userNameLabel.text = firstname + " " + lastname
//                    self.balanceAmountLabel.text = balanceString
//
////                    self.tableView.reloadData()
//                    print("that's all done for you")
//
//                } else {
//                    print("Document does not exist")
//                }
//            }
//        }
//    }
    
    func setUpProfilePic() {
        
        let uid = Auth.auth().currentUser?.uid
//        let image = genericProfilePic
//        profilePicView.image = image
        
//        profilePicView.layer.borderWidth = 3.0
//        profilePicView.layer.borderColor = UIColor.white.cgColor
        profilePicView.layer.cornerRadius = profilePicView.frame.width/2
        profilePicView.clipsToBounds = true
//        self.profilePicView.layer.borderWidth = 5.0
        
        // this checks for change of profile pic (from within app)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfilePicView), name: Notification.Name("newProfilePicUploaded"), object: nil)
        
        // uncomment these lines if you want to do something with a profile pic tap
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profilePicTapped(tapGestureRecognizer:)))
//
//        profilePicView.addGestureRecognizer(tapGestureRecognizer)
        
//        if uid != nil {
//            // we only want to enable the profile pic editing if there's a pic to edit/if the user is logged in
//            self.profilePicView.isUserInteractionEnabled = true
//        }
        
        
        // on load, get the profile pic from Firebase Storage
        updateProfilePicView()
    }
    
    @objc func updateProfilePicView() {

            if let uid = Auth.auth().currentUser?.uid {
                let storageRef = Storage.storage().reference().child("profilePictures").child(uid)

                storageRef.downloadURL { url, error in
                    guard let url = url else { return }

    //                let processor = DownsamplingImageProcessor(size: self.profilePicView.frame.size)
    //                    >> RoundCornerImageProcessor(cornerRadius: 20)
                    self.profilePicView.kf.indicatorType = .activity
                    
                    // using Kingfisher library for tidy handling of image download
                    self.profilePicView.kf.setImage(
                        with: url,
                        placeholder: UIImage(named: "icons8-user-50"),
                        options: [
                            .scaleFactor(UIScreen.main.scale),
                            .transition(.fade(1)),
                            .cacheOriginalImage
                        ])
                    {
                        result in
                        switch result {
                            // TODO add better error handling
                        case .success(let value):
                           
                            self.profilePic = value.image
                        case .failure(let error):
                            print("Job failed: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // user isn't logged in...?
            }
        }
    
    func showAlert(title: String, message: String?, segueIdentifier: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            do {
                try Auth.auth().signOut()
                // update the userAccountExists flag (if user signs in with a different number, we don't want this flag to persist in memory and mess things up
                UserDefaults.standard.set(false, forKey: "userAccountExists")
            } catch let err {
                // TODO what if signout fails e.g. no connection
            }
            self.performSegue(withIdentifier: segueIdentifier, sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is EditProfileTableViewController {
            let vc = segue.destination as! EditProfileTableViewController
            
            if let fn = self.firstname, let ln = self.lastname, let em = self.email {
                vc.firstname = fn
                vc.lastname = ln
                vc.email = em
            }
            
            if let pp = self.profilePic {
                vc.profilePic = pp
            }
        }
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
}
