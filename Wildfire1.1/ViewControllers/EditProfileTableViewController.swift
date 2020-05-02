//
//  EditProfileTableViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 23/01/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditProfileTableViewController: UITableViewController {

    var fullname = ""
    var email = ""
    var profilePic: UIImage?
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var profilePicView: UIImageView!
        
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBAction func nameEdited(_ sender: Any) {
        saveButton.isEnabled = true
        saveButton.title = "Save"
    }
    
    @IBAction func emailEdited(_ sender: Any) {
        saveButton.isEnabled = true
        saveButton.title = "Save"
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if let uid = Auth.auth().currentUser?.uid, let name = nameTextField.text, let email = emailTextField.text {
            Firestore.firestore().collection("users").document(uid).setData(["fullname": name, "email": email]
            // merge: true is IMPORTANT - prevents complete overwriting of a document if a user logs in for a second time, for example, which could wipe important data (including the balance..)
            , merge: true) { (error) in
                // print(result!.user.uid)
                if error != nil {
                    // Show error message
                    
                } else {
                    
                    // progress: true presents next screen
                    self.showAlert(title: "Great! That's updated for you.", message: nil, progress: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUpTextFields()

        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        
        saveButton.isEnabled = false
        saveButton.title = ""
        showProfilePic()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            performSegue(withIdentifier: "showEditProfilePic", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showAlert(title: String?, message: String?, progress: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if progress == true {
                self.performSegue(withIdentifier: "unwindToPrevious", sender: self)
            }
        }))
        self.present(alert, animated: true)
    }
    
    func showProfilePic() {
        
        profilePicView.layer.cornerRadius = profilePicView.frame.width/2
        if let pp = profilePic {
            profilePicView.image = pp
        }
    }
    
    func setUpTextFields() {
        nameTextField.text = fullname
        emailTextField.text = email
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ProfilePicViewController {
            let vc = segue.destination as! ProfilePicViewController
            
            if let cpp = profilePic {
                vc.currentProfilePic = cpp
            }
        }
    }
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


}
