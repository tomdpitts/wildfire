//
//  DriverLicenceFrontUploadViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 02/03/2020.
//  Copyright © 2020 Wildfire. All rights reserved.
//

import UIKit
import AlamofireImage

class DriverLicenceFrontUploadViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var frontImage: UIImage?
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var editImageButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isHidden = true
        
        Utilities.styleHollowButton(editImageButton)
        Utilities.styleHollowButton(nextButton)
        pictureView.clipsToBounds = true
        pictureView.layer.cornerRadius = pictureView.frame.width/40
        pictureView.layer.borderWidth = 5.0 //Or some other value
        pictureView.layer.borderColor = UIColor(hexString: "#39C3C6").cgColor
    }
    
    @IBAction func editImageButton(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            
            // and scale a version to display (possibly not strictly necessary)
            let size = CGSize(width: self.pictureView.frame.width, height: self.pictureView.frame.height)
            let aspectScaleImage = image.af.imageAspectScaled(toFit: size)
            
            self.pictureView.image = aspectScaleImage
            
            // contentMode needs to be updated from "center" (which ensures the icons8 'rescan'icon doesn't look stretched or blurry) to scaleAspectFill to best render the image
            self.pictureView.contentMode = .scaleAspectFill
            
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
            
            self.frontImage = aspectScaleImage
            self.editImageButton.setTitle("Change Image", for: .normal)
            self.nextButton.isHidden = false
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DriverLicenceBackUploadViewController {
            let vc = segue.destination as! DriverLicenceBackUploadViewController

            if let front = self.frontImage {
                        
                    vc.frontImage = front
                }
            }
    }

}
