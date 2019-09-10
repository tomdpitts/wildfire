//
//  ReceiveViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ReceiveViewController: UIViewController {
    
    

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var imgQRCode: UIImageView!
    
    @IBOutlet weak var btnAction: UIButton!
    
    var ref:DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        textField.delegate = self as? UITextFieldDelegate
        textField.keyboardType = .decimalPad
        // N.B. You need to make sure users can't copy and paste non numeric characters into field
        // which hasn't been added yet, only the textField type. If there's no actual field and
        // the numbers are all back end, I don't think there's any point adding it now.
        
    }
    
    var qrcodeImage: CIImage!;
    
    @IBAction func pressedButton(_ sender: Any) {
        if qrcodeImage == nil {
            if textField.text == "" {
                return
            }
            
            let data = textField.text!.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            
            filter!.setValue(data, forKey: "inputMessage")
            filter!.setValue("Q", forKey: "inputCorrectionLevel")
            
            qrcodeImage = filter!.outputImage
            
            displayQRCodeImage()
            
            textField.resignFirstResponder()
            btnAction.setTitle("Clear",for: .normal)
            
        }
            
        else {
            imgQRCode.image = nil
            qrcodeImage = nil
            btnAction.setTitle("Generate",for: .normal)
            
            
        }
        
    }
    func displayQRCodeImage() {
        
        let scaleX = imgQRCode.frame.size.width / qrcodeImage.extent.size.width
        let scaleY = imgQRCode.frame.size.height / qrcodeImage.extent.size.height
        
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        imgQRCode.image = UIImage(ciImage: transformedImage)
        
        
    }
    
    func encryptor() {
    
        if let heimdall = Heimdall(tagPrefix: "com.example") {
            let testString = "This is a test string"
            
            // Encryption/Decryption
            if let encryptedString = heimdall.encrypt(testString) {
                println(encryptedString) // "cQzaQCQLhAWqkDyPoHnPrpsVh..."
                
                if let decryptedString = heimdall.decrypt(encryptedString) {
                    println(decryptedString) // "This is a test string"
                }
            }
            
            // Signatures/Verification
            if let signature = heimdall.sign(testString) {
                println(signature) // "fMVOFj6SQ7h+cZTEXZxkpgaDsMrki..."
                var verified = heimdall.verify(testString, signatureBase64: signature)
                println(verified) // True
                
                // If someone meddles with the message and the signature becomes invalid
                verified = heimdall.verify(testString + "injected false message",
                                           signatureBase64: signature)
                println(verified) // False
            }
        }
        
    }
        
}

