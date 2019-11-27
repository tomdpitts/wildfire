//
//  AccountViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import SDWebImage
import Kingfisher

// TODO add a auth listener to trigger profile pic refresh when signed in status changes
class AccountViewController: UIViewController {
    
    var global: GlobalVariables!
    
    var currentProfilePic = UIImage(named: "genericProfilePic")
    
    @IBOutlet var accountBalance: UILabel!
    @IBOutlet weak var uidLabel: UILabel!

    @IBOutlet weak var profilePicView: UIImageView!
    
    @IBOutlet weak var setUpAccountButton: UIButton!
    @IBOutlet weak var addPaymentMethodButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    // This 'ref' property will hold a firebase database reference
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    // Declare variable to hold account balance
    var liveBalance: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let utilities = Utilities()
        utilities.checkForUserAccount()
        
        // this all needs to be updated to point to Firestore, not RT database
        
        // set the firebase reference
        ref = Database.database().reference()
        
        // set new reference to the accounts branch specifically
        let accountsRef = ref?.child("accounts")
        
        // set new reference to the specific user's account node
        let userRef = accountsRef?.child("1001")
        
        userRef?.observeSingleEvent(of: .childAdded, with: { (snapshot) in
            let balance = snapshot.value!
            print(balance)
            
            
            self.accountBalance.text = "\(String(describing: balance))"
            self.liveBalance = String(describing: balance)
            
        })
        
        // set up the listener to listen out for changes to user's account node
    databaseHandle = userRef?.observe(.childChanged, with: {(snapshot) -> Void in
        
        // self.accountBalance.text = "edited"
        
        let balance = snapshot.value!
        
        if balance != nil {
            self.accountBalance.text = "\(String(describing: balance))"
            self.liveBalance = String(describing: balance)
            
        }
    })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        setUpProfilePic()
        setUpButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ProfilePicViewController {
            let destination = segue.destination as! ProfilePicViewController
            if let pic = self.currentProfilePic {
                destination.currentProfilePic = pic
            } else { return }
        }
    }
    
    @objc func profilePicTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        // this line doesn't seem to be necessary
//        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        performSegue(withIdentifier: "profilePicSegue", sender: self)
    }
    
    @IBAction func refreshUID(_ sender: Any) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.uidLabel.text = "Not logged in"
            return
        }
        self.uidLabel.text = uid
    }
    
    
    @IBAction func goToLogin(_ sender: UIButton) {
        performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    
    // this unwind segue is deliberately generic! Allows the Back button on PaymentSetupVC to unwind to the appropriate VC depending on where it came from
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    // This unwind segue exists independently to the above to allow a specific unwind call e.g. in LoginVC
    @IBAction func unwindToAccountView(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        
        // Declare Alert message
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            self.signOut()
            self.updateProfilePicView()
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)

        
        
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let err {
            print(err)
        }
    }
    
    func setUpButtons() {
        
        // disabling signout button as probably no longer needed
        signOutButton.isHidden = true
        signOutButton.isEnabled = false
        
        Utilities.styleFilledButton(setUpAccountButton)
        Utilities.styleFilledButton(addPaymentMethodButton)
        Utilities.styleFilledButton(signOutButton)
        
        // depending on whether User has completed full signup or not, we want to show different options here
        if global.userAccountExists == true {
            setUpAccountButton.isHidden = true
            setUpAccountButton.isEnabled = false
        }
    }
    
    func setUpProfilePic() {
        
        let uid = Auth.auth().currentUser?.uid
        
        profilePicView.image = currentProfilePic
        profilePicView.layer.cornerRadius = profilePicView.frame.height/3
        
        // this checks for change of profile pic (from within app)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfilePicView), name: Notification.Name("newProfilePicUploaded"), object: nil)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profilePicTapped(tapGestureRecognizer:)))
        
        profilePicView.addGestureRecognizer(tapGestureRecognizer)
        
        if uid != nil {
            // we only want to enable the profile pic editing if there's a pic to edit/if the user is logged in
            self.profilePicView.isUserInteractionEnabled = true
        }
        
        
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
                    // TODO add placeholder image
                    placeholder: UIImage(named: "placeholderImage"),
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
                        self.currentProfilePic = value.image
                    case .failure(let error):
                        print("Job failed: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            currentProfilePic = UIImage(named: "genericProfilePic")
        }
    }
}


