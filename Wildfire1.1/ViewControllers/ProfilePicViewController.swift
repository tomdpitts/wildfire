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
import AlamofireImage


class ProfilePicViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var currentProfilePic: UIImage?
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var confirmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.isHidden = true
        confirmButton.isEnabled = false
        
        // set the profile pic, if it exists
        if let cpp = currentProfilePic {
            pictureView.image = cpp
        }
        
        Utilities.styleHollowButton(confirmButton)
//        pictureView.layer.cornerRadius = pictureView.frame.height/3
    }
    

    @IBAction func confirmButtonTapped(_ sender: Any) {
        let image = self.pictureView.image
        uploadProfilePic(imageToUpload: image)
        performSegue(withIdentifier: "unwindToPrevious", sender: self)
    }
    
    
    
    @IBAction func editProfilePicButton(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            
            let size = CGSize(width: 200.0, height: 200.0)
            let aspectScaleImage = image.af.imageAspectScaled(toFill: size)
            let circleImage = aspectScaleImage.af.imageRoundedIntoCircle()
            self.pictureView.image = circleImage
            
            self.confirmButton.isHidden = false
            self.confirmButton.isEnabled = true
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
    
    // is this func required?
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {

        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    fileprivate func uploadProfilePic(imageToUpload: UIImage?) {
        // let's give the filename as the user id for simplicity
        guard let filename = Auth.auth().currentUser?.uid,
            let profilePic = imageToUpload else { return }
        
        
        guard let uploadData = profilePic.jpegData(compressionQuality: 0.9) else { return }
        
        let storageRef = Storage.storage().reference().child("profilePictures").child(filename)
        let uploadTask = storageRef.putData(uploadData, metadata: nil) { (metadata, err) in
            if let err = err {
                print(err)
                return
            }
            
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
//        uploadTask.observe(.success) { snapshot in
//            NotificationCenter.default.post(name: Notification.Name("newProfilePicUploaded"), object: nil)
//            // Fetch the download URL
//        }
    }
}
