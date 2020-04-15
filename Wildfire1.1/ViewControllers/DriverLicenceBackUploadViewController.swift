//
//  DriverLicenceBackUploadViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import AlamofireImage

class DriverLicenceBackUploadViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var frontImage: UIImage?

    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var editImageButton: UIButton!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        confirmButton.isHidden = true
        
        Utilities.styleHollowButton(editImageButton)
        Utilities.styleHollowButton(confirmButton)
        pictureView.clipsToBounds = true
        pictureView.layer.cornerRadius = pictureView.frame.width/40
        pictureView.layer.borderWidth = 5.0 //Or some other value
        pictureView.layer.borderColor = UIColor(hexString: "#39C3C6").cgColor
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        guard let frontImage = self.frontImage else { return }
        guard let backImage = self.pictureView.image else { return }
        
        uploadDocument(pages: 2, frontImage: frontImage, backImage: backImage)
    }
    
    @IBAction func editImageButton(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            
            // and scale a version to display (possibly not strictly necessary)
            let size = CGSize(width: self.pictureView.frame.width, height: self.pictureView.frame.height)
            let aspectScaleImage = image.af_imageAspectScaled(toFill: size)
            
            self.pictureView.image = aspectScaleImage
            // contentMode needs to be updated from "center" (which ensures the icons8 'rescan'icon doesn't look stretched or blurry) to scaleAspectFill to best render the image
            self.pictureView.contentMode = .scaleAspectFill
            
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
            
            self.editImageButton.setTitle("Change Image", for: .normal)
            self.confirmButton.isHidden = false
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
    
    func uploadDocument(pages: Int, frontImage: UIImage, backImage: UIImage) {
        editImageButton.isEnabled = false
        confirmButton.isEnabled = false
        
        guard let mangopayID = UserDefaults.standard.string(forKey: "mangopayID") else { return }
    
        self.showSpinner(titleText: "Securely uploading", messageText: "Please allow up to 60 seconds")
        
        let frontImageToUpload = convertImageToBase64(frontImage)
        let backImageToUpload = convertImageToBase64(backImage)
        
        functions.httpsCallable("addKYCDocument").call(["mangopayID": mangopayID, "pages": pages, "firstBase64Image": frontImageToUpload, "secondBase64Image": backImageToUpload]) { (result, error) in

            self.removeSpinner()
            if error != nil {
                self.showAlert(title: "That didn't work for some reason", message: "Sorry about that. This just means we couldn't complete the upload. Please ensure you have an internet connection and try again.")
                self.editImageButton.isEnabled = true
                self.confirmButton.isEnabled = true
            } else {
                UserDefaults.standard.set(true, forKey: "KYCPending")
                self.performSegue(withIdentifier: "showKYCSuccessScreen", sender: self)
            }
        }
        return
    }
    
    func convertImageToBase64(_ image: UIImage) -> String {
        
        //Use image to create into NSData format
        let imageData = image.pngData()!
        
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        
        return strBase64
    }
    
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        
        self.present(alert, animated: true)
    }
}
