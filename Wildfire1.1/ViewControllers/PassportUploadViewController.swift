//
//  PassportUploadViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import Alamofire

class PassportUploadViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var fullResImage: UIImage?
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var editImageButton: UIButton!
    
    @IBOutlet weak var confirmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.isHidden = true
        
        Utilities.styleHollowButton(confirmButton)
//        pictureView.layer.cornerRadius = pictureView.frame.height/3
    }
    
    @IBAction func editImageButton(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            
            // store a full resolution image, ready for upload
            self.fullResImage = image
            
            // and scale a version to display (possibly not strictly necessary)
            let size = CGSize(width: 200.0, height: 200.0)
            let aspectScaleImage = image.af_imageAspectScaled(toFill: size)
            
            self.pictureView.image = aspectScaleImage
            
            self.confirmButton.isHidden = false
        }
    }

    @IBAction func confirmButtonTapped(_ sender: Any) {
        let image = self.pictureView.image
        uploadDocument(pages: 1)
        
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
    
//    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
//
//        let scale = newWidth / image.size.width
//        let newHeight = image.size.height * scale
//        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
//        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
//
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return newImage
//    }
    
    func uploadDocument(pages: Int) {
        
        guard let mangopayID = UserDefaults.standard.string(forKey: "mangopayID") else { return }
        
        let url = "https://api.sandbox.mangopay.com/v2.01/wildfirewallet/users/\(mangopayID)/kyc/documents"
        
        guard let selectedImage = fullResImage else { return }
        
        let imageToUpload = convertImageToBase64(selectedImage)
    
        print(imageToUpload)
        
        let parameters = [
            "Type": "IDENTITY_PROOF"
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters).validate().responseString(completionHandler: { response in
            if let error = response.error {
//                completion("nil", error)
                print(error)
            } else if let dataString = response.data {
//                completion(dataString, nil)
                print(dataString)
                
            }
        })
        return
    }
    
    func convertImageToBase64(_ image: UIImage) -> String {
        
        //Use image to create into NSData format
        let imageData = image.pngData()!
        
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        
        return strBase64
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    
//    func uploadProfilePic(imageToUpload: UIImage?) {
//        
//        if let scan = fullResImage {
//            functions.httpsCallable("listCards").call() { (result, error) in
//
//                if let cardList = result?.data as? [[String: Any]] {
//                    let defaults = UserDefaults.standard
//                    
//                    defaults.set(cardList.count, forKey: "numberOfCards")
//                    
//                    let count = cardList.count
//                    
//                    if count > 0 {
//                        for i in 1...count {
//                            var cardNumber = ""
//                            var cardProvider = ""
//                            var expiryDate = ""
//                            
//                            let blob1 = cardList[i-1]
//                            if let cn = blob1["Alias"] as? String, let cp = blob1["CardProvider"] as? String, let ed = blob1["ExpirationDate"] as? String {
//                                
//                                cardNumber = String(cn.suffix(8))
//                                cardProvider = cp
//                                expiryDate = ed
//                            }
//                            let card = PaymentCard(cardNumber: cardNumber, cardProvider: cardProvider, expiryDate: expiryDate)
//                            
//                            defaults.set(try? PropertyListEncoder().encode(card), forKey: "card\(i)")
//                        }
//                    }
//                    
//                } else {
//                    print("nope")
//                }
//            }
//        }
//        
//        
//        
//        // let's give the filename as the user id for simplicity
//        guard let filename = Auth.auth().currentUser?.uid,
//            let profilePic = imageToUpload else { return }
//        
//        
//        guard let uploadData = profilePic.jpegData(compressionQuality: 0.9) else { return }
//        
//        let storageRef = Storage.storage().reference().child("profilePictures").child(filename)
//        let uploadTask = storageRef.putData(uploadData, metadata: nil) { (metadata, err) in
//            if let err = err {
//                print(err)
//                return
//            }
//        }
//        
//        
//        // template for deeper error handling TODO: complete this
//        uploadTask.observe(.failure) { snapshot in
//            if let error = snapshot.error as NSError? {
//                switch (StorageErrorCode(rawValue: error.code)!) {
//                case .objectNotFound:
//                    // File doesn't exist
//                    break
//                case .unauthorized:
//                    // User doesn't have permission to access file
//                    break
//                case .cancelled:
//                    // User canceled the upload
//                    break
//                    
//                    /* ... */
//                    
//                case .unknown:
//                    // Unknown error occurred, inspect the server response
//                    break
//                default:
//                    // A separate error occurred. This is a good place to retry the upload.
//                    break
//                }
//            }
//        }
//        uploadTask.observe(.success) { snapshot in
//            NotificationCenter.default.post(name: Notification.Name("newProfilePicUploaded"), object: nil)
//
//        }
//    }

}
