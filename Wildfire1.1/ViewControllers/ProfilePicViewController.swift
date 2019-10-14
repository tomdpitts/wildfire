//
//  ProfilePicViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import Kingfisher


class ProfilePicViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.isHidden = true
        confirmButton.isEnabled = false
        
    }

    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var confirmButton: UIButton!
    

    @IBAction func confirmButtonTapped(_ sender: Any) {
        let image = self.pictureView.image
        uploadProfilePic(imageToUpload: image)
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    
    
    @IBAction func editProfilePicButton(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            self.pictureView.image = image
            
            self.confirmButton.isHidden = false
            self.confirmButton.isEnabled = true
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
    
    fileprivate func uploadProfilePic(imageToUpload: UIImage?) {
        // let's give the filename as the user id for simplicity
        guard let filename = Auth.auth().currentUser?.uid,
            let profilePic = imageToUpload,
            let uploadData = profilePic.jpegData(compressionQuality: 0.4) else { return }
        
        let storageRef = Storage.storage().reference().child("profilePictures").child(filename)
        let uploadTask = storageRef.putData(uploadData, metadata: nil) { (metadata, err) in
            if let err = err {
                print(err)
                return
            }
        }
        // template for deeper error handling TODO: complete this
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    // File doesn't exist
                    break
                case .unauthorized:
                    // User doesn't have permission to access file
                    break
                case .cancelled:
                    // User canceled the upload
                    break
                    
                    /* ... */
                    
                case .unknown:
                    // Unknown error occurred, inspect the server response
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
            }
        }
        uploadTask.observe(.success) { snapshot in
            NotificationCenter.default.post(name: Notification.Name("newProfilePicUploaded"), object: nil)

        }
    }
}
