//
//  ReceiveViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import CryptoSwift


class ReceiveViewController: UIViewController, UITextFieldDelegate {
    
    // TODO prevent users from generating QR codes when no account (and crucially, no MangoPay wallet) exists yet
    // TODO in future, would be nice to add functionality to handle pending payments, so users can receive payments quickly upon first download, and add account info after the fact

    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var QRCodeImageView: UIImageView!
    
    @IBOutlet weak var btnAction: UIButton!
    @IBOutlet weak var saveToCameraRoll: UIButton!
    @IBOutlet weak var scanToPayLabel: UILabel!
    
    @IBAction func swipeGestureRecognizer(_ sender: Any) {
        // swipe down (and only down) hides keyboard
        self.view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                // The user's ID, unique to the Firebase project.
                // Do NOT use this value to authenticate with your backend server,
                // if you have one. Use getTokenWithCompletion:completion: instead.
                let uid = user.uid
                let email = user.email
                let photoURL = user.photoURL
                // ...
            }
        }
        
        amountTextField.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.title = "Receive"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        Utilities.styleHollowButton(saveToCameraRoll)
        
        saveToCameraRoll.isHidden = true
        scanToPayLabel.isHidden = true
        
        saveToCameraRoll.tintColor = UIColor(hexString: "#39C3C6")
        if #available(iOS 13.0, *) {
            saveToCameraRoll.setImage(UIImage(systemName: "square.and.arrow.up")?.withTintColor(UIColor(hexString: "#39C3C6")) , for: .normal)
        }
        
        amountTextField.delegate = self
        amountTextField.keyboardType = .decimalPad

        // N.B. You need to make sure users can't copy and paste non numeric characters into field
        // which hasn't been added yet, only the textField type. If there's no actual field and
        // the numbers are all back end, I don't think there's any point adding it now.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        
//        gradientBackground()
        
    }
    
    @IBAction func amountChanged(_ sender: Any) {
        // revert to empty state
        QRCodeImageView.image = UIImage(named: "QR Border3 TEAL")
        qrcodeImage = nil
//        btnAction.setTitle("Show code",for: .normal)
        btnAction.isHidden = false
        saveToCameraRoll.isHidden = true
        scanToPayLabel.isHidden = true
        
        // reset Save to Camera Roll Button
        saveToCameraRoll.setTitle("Save to Camera Roll", for: .normal)
        Utilities.styleHollowButton(saveToCameraRoll)
        if #available(iOS 13.0, *) {
            saveToCameraRoll.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        }
        saveToCameraRoll.isEnabled = true
        
    }
    
    @IBAction func amountFinishedEditing(_ sender: Any) {
        
        guard let amountString = amountTextField.text else { return }
        
        let numberOfDecimalDigits: Int
        
        if let dotIndex = amountString.firstIndex(of: ".") {
            // prevent more than 2 digits after the decimal
            numberOfDecimalDigits = amountString.distance(from: dotIndex, to: amountString.endIndex) - 1
            
            if numberOfDecimalDigits == 1 {
                let replacementString = amountString + "0"
                amountTextField.text = replacementString
                
            } else if numberOfDecimalDigits == 0 {
                let replacementString = String(amountString.dropLast())
                amountTextField.text = replacementString
            }
        }
    }
    
    
    var qrcodeImage: CIImage!;
    
    @IBAction func pressedButton(_ sender: Any) {
        if qrcodeImage == nil {
            
            if amountTextField.text == "" {
                return
            }
            
            let qrdata = generateQRString().data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            
            filter!.setValue(qrdata, forKey: "inputMessage")
            filter!.setValue("Q", forKey: "inputCorrectionLevel")
            
            qrcodeImage = filter!.outputImage
            
            displayQRCodeImage()
            
            amountTextField.resignFirstResponder()
//            btnAction.setTitle("Clear",for: .normal)
            btnAction.isHidden = true
            
            saveToCameraRoll.isHidden = false
            scanToPayLabel.isHidden = false
            
        }
            
        // old code, redundant now that the 'go' button disappears upon submission, and retries are handled by text field changed function
        else {
            // revert to empty state
            QRCodeImageView.image = UIImage(named: "QR Border3 TEAL")
            qrcodeImage = nil
//            btnAction.setTitle("Show code",for: .normal)
            btnAction.isHidden = false
            saveToCameraRoll.isHidden = true
            scanToPayLabel.isHidden = true
            
            // reset Save to Camera Roll Button (currently hidden)
            saveToCameraRoll.setTitle("Save to Camera Roll", for: .normal)
            Utilities.styleHollowButton(saveToCameraRoll)
            if #available(iOS 13.0, *) {
                saveToCameraRoll.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
            }
            saveToCameraRoll.isEnabled = true
        }
    }
    
    func displayQRCodeImage() {

        
        let border = UIImage(named: "QR Border3 TEAL")!
        let logo = UIImage(named: "Logo70pxTEALBORDER")!
        
        let scaleX = QRCodeImageView.frame.size.width / qrcodeImage.extent.size.width
        
        let scaleY = QRCodeImageView.frame.size.height / qrcodeImage.extent.size.height
        
        let transformedImage = UIImage(ciImage: qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY)))
        
        let overlayQR = mergeImage(bottomImage: border, topImage: transformedImage, scalePercentage: 71)
        
        let overlayWildfireLogo = mergeImage(bottomImage: overlayQR, topImage: logo, scalePercentage: 23)
        
        QRCodeImageView.image = overlayWildfireLogo
    }
    
    func generateQRString() -> String {
        
        var receiveAmountString = ""
        
        // validator is text that will be appended to the beginning of the string - this is a failsafe to essentially ensure that the decrypted string is from Wildfire (lyrics are not all in the right order)
        let validator = """
            Einstein, James Dean, Brooklyn's got a winning team, Bardot, Budapest, Alabama, Krushchev
            """
        
        if let receiveAmount = amountTextField.text {
            if let float = Float(receiveAmount) {
                
                let receiveAmountCents = float*100
                let receiveAmount7 = Int(receiveAmountCents*7)
                receiveAmountString = String(receiveAmount7)
            }
        } else {
            receiveAmountString = ""
        }
        
        
        let uid = Auth.auth().currentUser!.uid
        
        let qrdata = validator + receiveAmountString + uid
        
        let aes = try? AES(key: "afiretobekindled", iv: "av3s5e12b3fil1ed")
        
        let encryptedString = try? aes!.encrypt(Array(qrdata.utf8))
        
        let stringQR = encryptedString?.toHexString()

        
        return stringQR!
    }
    
    func mergeImage(bottomImage: UIImage, topImage: UIImage, scalePercentage: Int) -> UIImage {
        
        let width = 300
        let height = 300
        
        let scaledWidth = CGFloat(width*scalePercentage)/100
        
        let scaledHeight = CGFloat(height*scalePercentage)/100

        
        
        let fullImageSize = CGSize(width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(fullImageSize, true, 0.0)

        let areaSizeBottom = CGRect(x: 0, y: 0, width: fullImageSize.width, height: fullImageSize.height)
        
        // add bottom layer
        bottomImage.draw(in: areaSizeBottom)
        
//        let sizeTop = CGSize(width: scaledWidth, height: scaledHeight)
        
        let centerX = (CGFloat(width) - scaledWidth) / 2.0
        
        let centerY = (CGFloat(height) - scaledHeight) / 2.0
        
        
        let areaSizeTop = CGRect(x: centerX, y: centerY, width: scaledWidth, height: scaledHeight)

        // add top layer
        topImage.draw(in: areaSizeTop, blendMode: .normal, alpha: 1.0)

        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    @IBAction func saveToCameraRollTapped(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(QRCodeImageView.image!, nil, nil, nil)
        
        saveToCameraRoll.isEnabled = false
        
        // change the look to show it has been selected and is now disabled as a button
        Utilities.styleHollowButtonSELECTED(saveToCameraRoll)
        
        saveToCameraRoll.setTitle("Done!", for: .normal)
        if #available(iOS 13.0, *) {
            saveToCameraRoll.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        }
    }
    
    @objc func DismissKeyboard(){
    //Causes the view to resign from the status of first responder.
    view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            return true
        }

        let newText = oldText.replacingCharacters(in: r, with: string)
        let isNumeric = newText.isEmpty || (Double(newText) != nil)
        let numberOfDots = newText.components(separatedBy: ".").count - 1

        let numberOfDecimalDigits: Int
        if let dotIndex = newText.firstIndex(of: ".") {
            // prevent more than 2 digits after the decimal
            numberOfDecimalDigits = newText.distance(from: dotIndex, to: newText.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }

        return isNumeric && numberOfDots <= 1 && numberOfDecimalDigits <= 2
    }
    
    func gradientBackground() {
        // Create a gradient layer
        let gradientLayer = CAGradientLayer()
        // Set the size of the layer to be equal to size of the display
        gradientLayer.frame = view.bounds
        // Set an array of Core Graphics colors (.cgColor) to create the gradient
        gradientLayer.colors = [Style.secondaryThemeColour.cgColor, UIColor(hexString: "#ffffff").cgColor]

        gradientLayer.locations = [0.0, 0.25]
        // Rasterize this static layer to improve app performance
        gradientLayer.shouldRasterize = true
        // Apply the gradient to the backgroundGradientView
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

