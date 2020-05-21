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
import FirebaseFunctions
import Kingfisher
import LocalAuthentication

class Account2ViewController: UITableViewController {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    static var listener: ListenerRegistration?

    var justCompletedSignUp = false
    var imageWasChanged = false
    
    var genericProfilePic = UIImage(named: "Logo70px")
    var balance: Int?
    var fullname: String?
    var email: String?
    var profilePic: UIImage?
    
    var balanceAmount: Float = 0
    var balanceString: String?

    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
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
        
        loadingIndicator.isHidden = true
        // .medium for iOS 13 onwards, .gray is deprecated but older iOS versions don't have .medium
        if #available(iOS 13.0, *) {
            loadingIndicator.style = .medium
        } else {
            loadingIndicator.style = .gray
        }
                
//        // TODO roll this out across the board?
//        tableView.backgroundView = GradientView()
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        // we only need this cell if there's no account yet
        if UserDefaults.standard.bool(forKey: "userAccountExists") == true {
            noAccountYetCell.isHidden = true
        }
    }
    
    // this exists only for the case where user has just completed sign up flow, and we want to refresh the account view. Without this code, user still only sees the 'set up account' tableview cell. In all other cases, justCompletedSignUp is false
    override func viewWillAppear(_ animated: Bool) {
        if justCompletedSignUp == true {
            self.tableView.reloadData()
            getUserInfo()
            setUpProfilePic()
            noAccountYetCell.isHidden = true
            justCompletedSignUp = false
        }
        
        if imageWasChanged == true {
            profilePicView.alpha = 0.4
            loadingIndicator.startAnimating()
            loadingIndicator.isHidden = false
        }
    }
    
    override func updateViewConstraints() {
        tableView.heightAnchor.constraint(equalToConstant: tableView.contentSize.height).isActive = true
        super.updateViewConstraints()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if UserDefaults.standard.bool(forKey: "userAccountExists") == false {
             return 2
        } else {
            return 12
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // aka sign out, signout, and logout
        if indexPath.row == 9 {
            let title = "Are you sure you want to Log Out?"
            // TODO a really nice user friendly feature would be to check whether balance is >0, and show a helpful hint to deposit if it is
            var message = ""
                
            if balanceAmount > Float(0.5) {
                
                let balanceString = String(format: "%.2f", balanceAmount)
                    
                message = "Just to let you know, your balance is £\(balanceString) - if you want to deposit it to your bank account, tap 'Cancel' and deposit to bank account. You can log back in at any time (with the same phone number), and your credit will still be here."
            } else {
                message = "You can log back in at any time (with the same phone number), and your credit will still be here."
            }
            
            let segue = "unwindToWelcome"
            showLogOutAlert(title: title, message: message, segueIdentifier: segue)
        } else if indexPath.row == 10 {
            
            // Delete Account Selected
            
            if balanceAmount > Float(0) {
                
                let balanceString = String(format: "%.2f", balanceAmount)

                let title = "Are you sure you want to delete your account?"
                let message = "You still have £\(balanceString) credit. Remaining credit cannot be reimbursed after deletion, so you are strongly advised to deposit remaining funds to your bank account before deletion."
                
                let segue = "showDeleteAccount"
                
                self.universalShowAlert(title: title, message: message, segue: segue, cancel: true)


            } else {

                let title = "Delete Account"
                let message = "Your account info will be deleted - this action cannot be undone."
                
                let segue = "showDeleteAccount"
                
                self.universalShowAlert(title: title, message: message, segue: segue, cancel: true)
            }
            
        } else if indexPath.row == 11 {
            performSegue(withIdentifier: "showAbout", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // this is simply to remove the "set up account" cell by setting cell height to 0 in the case that userAccountExists == false
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if UserDefaults.standard.bool(forKey: "userAccountExists") == true {
            if (indexPath.row == 1) {
                let rowHeight: CGFloat = 0.0
                return rowHeight
            } else {
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    func getUserInfo() {
        if let uid = Auth.auth().currentUser?.uid {
            let docRef = Firestore.firestore().collection("users").document(uid)

//
//            docRef.getDocument { (document, error) in
//
//                if let err = error {
//                    print(err)
//                }
//                if let document = document, document.exists {
//                    let data = document.data()
//                    print(data)
//                } else {
//                    print("Document does not exist")
//                }
//            }
            
            docRef.addSnapshotListener { documentSnapshot, error in
                
                if let error = error {
                    print("Error retreiving collection: \(error)")
                } else {
                
                    guard let document = documentSnapshot else {

                        print("Error fetching document: \(error!)")
                        return
                    }
                    
                    guard let data = document.data() else {
                        print("Document data was empty.")
                        return
                    }
                    print(data)
                    
                    let fullname = data["fullname"] as! String
                    let balance = data["balance"] as! Int
                    let balanceFloat = Float(balance)/100
                    let balanceString = String(format: "%.2f", balanceFloat)

                    let email = data["email"] as! String

                    self.email = email
                    self.fullname = fullname

                    self.userNameLabel.text = fullname
                    self.balanceAmountLabel.text = "Balance: £\(balanceString)"
                    self.balanceString = balanceString
                    self.balanceAmount = balanceFloat
                }
            }
        }
    }
    
    func setUpProfilePic() {
        
//        // set the generic image immediately
//        profilePicView.image = genericProfilePic
        
//        profilePicView.layer.borderWidth = 3.0
//        profilePicView.layer.borderColor = UIColor.white.cgColor
        profilePicView.layer.cornerRadius = profilePicView.frame.width/2
        profilePicView.clipsToBounds = true
//        self.profilePicView.layer.borderWidth = 5.0
        
        
        // this checks for change of profile pic (from within app)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfilePicView), name: Notification.Name("newProfilePicUploaded"), object: nil)
        
        
        // on load, get the profile pic from Firebase Storage
        updateProfilePicView()
    }
    
    @objc func updateProfilePicView() {
        
        if let url = UserDefaults.standard.url(forKey: "profilePicURL") {
            
            // using Kingfisher library for tidy handling of image download
            self.profilePicView.kf.setImage(with: url,
                placeholder: self.genericProfilePic,
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
                    self.genericProfilePic = value.image
                    
                    if self.loadingIndicator.isHidden == false {
                        self.profilePicView.alpha = 1.0
                        self.imageWasChanged = false
                        self.loadingIndicator.isHidden = true
                        self.loadingIndicator.stopAnimating()
                    }
                case .failure(let error):
                    self.profilePicView.alpha = 1.0
                    self.imageWasChanged = false
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    print("Job failed: \(error.localizedDescription)")
                }
            }
        } else {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let storageRef = Storage.storage().reference().child("profilePictures").child(uid)
                
            storageRef.downloadURL { url, error in
                if error != nil {
                // Handle any errors
                } else {
                    guard let URL = url else { return }
                    UserDefaults.standard.set(URL, forKey: "profilePicURL")
                    NotificationCenter.default.post(name: Notification.Name("newProfilePicUploaded"), object: nil)
                }
            }
        }
    }
    
    func showLogOutAlert(title: String, message: String?, segueIdentifier: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            do {
                // surprisingly enough, it seems the currentUser persists on the client even when deletion has been triggered, so we'll always call signOut()
                try Auth.auth().signOut()
                // update the userAccountExists flag (if user signs in with a different number, we don't want this flag to persist in memory and mess things up
                self.resetUserDefaults()
                
                self.performSegue(withIdentifier: segueIdentifier, sender: self)
                
            } catch let err {
                // TODO what if signout fails e.g. no connection
                print(err)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is EditProfileTableViewController {
            let vc = segue.destination as! EditProfileTableViewController
            
            if let fn = self.fullname, let em = self.email {
                vc.fullname = fn
                vc.email = em
            }
            
            if let pp = self.profilePic {
                vc.profilePic = pp
            }
        } else if segue.destination is TopUpViewController {
            let vc = segue.destination as! TopUpViewController
            
            if let currentBalance = self.balanceString {
                vc.currentBalance = currentBalance
            }
        } else if segue.destination is DeleteAccountViewController {
            let vc = segue.destination as! DeleteAccountViewController
            
            if self.balanceAmount > 0 {
                vc.remainingCredit = true
            }
        }
        
        
    }
    
    func resetUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
    @IBAction func unwindToAccountView(_ unwindSegue: UIStoryboardSegue) {
    }
}
