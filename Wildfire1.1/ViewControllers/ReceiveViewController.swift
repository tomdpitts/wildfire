//
//  ReceiveViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDynamicLinks
import FirebaseStorage
import FirebaseAnalytics
import CryptoSwift


class ReceiveViewController: UIViewController, UITextFieldDelegate {
    
    var receiveAmount: String?
    let uid = Auth.auth().currentUser?.uid
    let currency = "GBP"
    
    var shareLink: URL?
    
    let arrowUp = UIImage(named: "icons8-send-letter-50")
    
    // TODO prevent users from generating QR codes when no account (and crucially, no MangoPay wallet) exists yet
    // TODO in future, would be nice to add functionality to handle pending payments, so users can receive payments quickly upon first download, and add account info after the fact

    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var QRCodeImageView: UIImageView!
    
    @IBOutlet weak var btnAction: UIButton!
    @IBOutlet weak var saveToCameraRoll: UIButton!
//    @IBOutlet weak var scanToPayLabel: UILabel!
    @IBOutlet weak var shareLinkButton: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    @IBAction func swipeGestureRecognizer(_ sender: Any) {
        // swipe down (and only down) hides keyboard
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // .medium for iOS 13 onwards, .gray is deprecated but older iOS versions don't have .medium
        if #available(iOS 13.0, *) {
            loadingSpinner.style = .medium
        } else {
            loadingSpinner.style = .gray
        }

        Utilities.styleHollowButton(saveToCameraRoll)
        Utilities.styleHollowButton(shareLinkButton)
                
        saveToCameraRoll.isHidden = true
//        scanToPayLabel.isHidden = true
        shareLinkButton.isHidden = true
        shareLinkButton.setImage(arrowUp?.changeAlpha(alpha: 0.0), for: .normal)
        loadingSpinner.isHidden = true
        
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
//        scanToPayLabel.isHidden = true
        shareLinkButton.isHidden = true
        shareLinkButton.isEnabled = false
        shareLinkButton.setImage(arrowUp?.changeAlpha(alpha: 0.0), for: .normal)
        loadingSpinner.isHidden = true
        
        // reset Save to Camera Roll Button
        saveToCameraRoll.setTitle("Save", for: .normal)
        Utilities.styleHollowButton(saveToCameraRoll)
        saveToCameraRoll.setImage(UIImage(named: "icons8-picture-50"), for: .normal)
        saveToCameraRoll.isEnabled = true
        
    }
    
    @IBAction func amountFinishedEditing(_ sender: Any) {
        
        guard let amountString = amountTextField.text else { return }
        
        var workString: String = amountString
        
        // 1: ensure amount is between 0.50 and 50
        
        guard let amountFloat = Float(workString) else { return }
        
        var x = amountFloat
        
        if x > 40.00 {
            x = 40
            self.universalShowAlert(title: "Max amount £40", message: "At this time, Wildfire can only transact amounts up to £40. This limit will be raised soon.", segue: nil, cancel: false)
        }
        
        if x < 0.5 {
            x = 0.5
            self.universalShowAlert(title: "Min amount £0.50", message: "At this time, Wildfire can only transact amounts above £0.50", segue: nil, cancel: false)
        }
        
        // 2: round to nearest 0.50
        
        let y = (Float(Int((2*x) + 0.5)))/2
        
        if x != y {
            self.universalShowAlert(title: "Apologies", message: "Only amounts in 50p increments can be transacted e.g. £3, £3.50, £4 etc.", segue: nil, cancel: false)
        }
        
        // 3: round to 2 decimal places
        
        let z = String(y)
        
        let numberOfDecimalDigits: Int
         
        if let dotIndex = z.firstIndex(of: ".") {
             // prevent more than 2 digits after the decimal
             numberOfDecimalDigits = z.distance(from: dotIndex, to: z.endIndex) - 1
             
             if numberOfDecimalDigits == 1 {
                 let replacementString = z + "0"
                 workString = replacementString
                 
             } else if numberOfDecimalDigits == 0 {
                 let replacementString = String(z.dropLast())
                 workString = replacementString
             }
        }
        
        amountTextField.text = workString
    }
    
    
    var qrcodeImage: CIImage!;
    
    @IBAction func pressedButton(_ sender: Any) {
        
        let userAccountExists: Bool? = UserDefaults.standard.bool(forKey: "userAccountExists")
        
        if userAccountExists == false || userAccountExists == nil {
            
            amountTextField.resignFirstResponder()
            
            self.universalShowAlert(title: "Please set up your account", message: "Just a few quick details are needed to receive payments", segue: "showAccountSetup", cancel: true)
            
            return
        } else {
            
            if amountTextField.text == "" {
                return
            }
                        
            guard let qrString = generateQRString() else { return }
            
            let qrData = qrString.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            
            filter!.setValue(qrData, forKey: "inputMessage")
            filter!.setValue("Q", forKey: "inputCorrectionLevel")
            
            qrcodeImage = filter!.outputImage
            
            displayQRCodeImage()
            
            amountTextField.resignFirstResponder()
//            btnAction.setTitle("Clear",for: .normal)
            btnAction.isHidden = true
            
            saveToCameraRoll.isHidden = false
//            scanToPayLabel.isHidden = false
            shareLinkButton.isHidden = false
            // show the buttons but don't enable shareLinkButton yet
            shareLinkButton.isEnabled = false
        }
            
        // old code, redundant now that the 'go' button disappears upon submission, and retries are handled by text field changed function
//        else {
//            // revert to empty state
//            QRCodeImageView.image = UIImage(named: "QR Border3 TEAL")
//            qrcodeImage = nil
////            btnAction.setTitle("Show code",for: .normal)
//            btnAction.isHidden = false
//            saveToCameraRoll.isHidden = true
////            scanToPayLabel.isHidden = true
//            shareLinkButton.isHidden = true
//            shareLinkButton.setImage(arrowUp?.changeAlpha(alpha: 0.0), for: .normal)
//            loadingSpinner.isHidden = true
//
//            // reset Save to Camera Roll Button (currently hidden)
//            saveToCameraRoll.setTitle("Save", for: .normal)
//            Utilities.styleHollowButton(saveToCameraRoll)
//            saveToCameraRoll.setImage(UIImage(named: "icons8-picture-50"), for: .normal)
//            saveToCameraRoll.isEnabled = true
//        }
    }
    
    func generateQRString() -> String? {
        
        var receiveAmountString = ""
        let currency = self.currency
        
        // validator is text that will be appended to the beginning of the string - this is to ensure that the decrypted string is from Wildfire
        let validator = """
            Einstein, James Dean, Brooklyn's got a winning team, Bardot, Budapest, Alabama, Krushchev
            """
        
        if let receiveAmount = amountTextField.text {
            
            if let float = Float(receiveAmount) {
                
                let receiveAmountCents = float*100
                
                // update class variable with amount in cents, so it can be included in dynamic link
                // first trim off the ".0" at the end
                let centsInt = Int(float)
                
                // required for dynamic link
                self.receiveAmount = String(centsInt)
                
                let receiveAmount7 = Int(receiveAmountCents*7)
                receiveAmountString = String(receiveAmount7)
                
                Analytics.logEvent(Event.QRGenerated.rawValue, parameters: [
                    EventVar.QRGenerated.generatedAmount.rawValue: float,
                    EventVar.QRGenerated.generatedCurrency.rawValue: currency
                ])
            }
        } else {
            self.universalShowAlert(title: "Something went wrong", message: "Please ensure you've entered a valid amount", segue: nil, cancel: false)
            return nil
        }
        
        
        if let uid = Auth.auth().currentUser?.uid {
        
            let qrdata = validator + receiveAmountString + currency + uid
            
            let aes = try? AES(key: "afiretobekindled", iv: "av3s5e12b3fil1ed")
            
            let encryptedString = try? aes!.encrypt(Array(qrdata.utf8))
            
            guard let stringQR = encryptedString?.toHexString() else { return nil }
            
            return stringQR
            
        } else {
            return nil
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
        
        self.uploadQR(QR: overlayWildfireLogo)
        
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
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
        
        Analytics.logEvent(Event.QRImageSaved.rawValue, parameters: nil)
        
        // change the look to show it has been selected and is now disabled as a button
        Utilities.styleHollowButtonSELECTED(saveToCameraRoll)
        
        saveToCameraRoll.setTitle("Done!", for: .normal)
        saveToCameraRoll.setImage(UIImage(named: "icons8-checked-50"), for: .normal)
    }
    
    func uploadQR(QR: UIImage) {
        
        guard let uid = self.uid else { return }
        
        loadingSpinner.isHidden = false
        loadingSpinner.startAnimating()
        
        let storage = Storage.storage()
        let nowString = "\(Date().timeIntervalSince1970)"
        
        // QR codes will be stored in user's folder under "QRCodes", with the current datetime as a filename (to more or less guarantee uniqueness)
        let storageRef = storage.reference().child("QRCodes/\(uid)/\(nowString).jpg")
        
        
        guard let uploadData = QR.jpegData(compressionQuality: 0.9) else { return }

        // Upload the file
        storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
          
            if error != nil {
                self.loadingSpinner.isHidden = true
                self.loadingSpinner.stopAnimating()
                self.shareLinkButton.imageView?.image = UIImage(named: "exclamationmark.triangle")
                self.shareLinkButton.imageView?.alpha = 1
            }
            
            storageRef.downloadURL { (url, error) in
                if let downloadURL = url {
                    self.generateLink(imageURL: downloadURL)
                }
            }
        }
    }
    
    func generateLink(imageURL: URL) {
        
        guard let uid = self.uid else { return }
        guard let amount = self.receiveAmount else { return }
        
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.wildfirewallet.com"
        components.path = "/imglink"
        
        let transactionQuery1 = URLQueryItem(name: "userID", value: uid)
        let transactionQuery2 = URLQueryItem(name: "amount", value: amount)
        let transactionQuery3 = URLQueryItem(name: "currency", value: self.currency)
        
        components.queryItems = [transactionQuery1, transactionQuery2, transactionQuery3]
        
        guard let linkParameter = components.url else { return }
        
        let dynamicLinksDomainURIPrefix = "https://wildfire.page.link"
        
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: dynamicLinksDomainURIPrefix) else {
            print("Couldn't create FDL components")
            return
        }
        
        if let bundleID = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
        }
        
        shareLink.iOSParameters?.appStoreID = "962194608"
        
        if let homepage = URL(string: "https://www.theverge.com") {
            shareLink.otherPlatformParameters?.fallbackUrl = homepage
        }
        
        // for future Android version!
//        linkBuilder.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
        
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        
        if let amount = amountTextField.text {
            shareLink.socialMetaTagParameters?.title = "£\(amount) - Pay with Wildfire"
        }
        shareLink.socialMetaTagParameters?.descriptionText = "The easiest and fastest way to pay"
        
        shareLink.socialMetaTagParameters?.imageURL = imageURL
        
        shareLink.shorten { (url, warnings, error) in
            if let error = error {
                print("Error in url shortener: \(error)")
                return
            }
            
            if let warnings = warnings {
                for warning in warnings {
                    print("FDL Warning: \(warning)")
                }
            }
            
            guard let url = url else { return }
            
            self.shareLink = url
            
            self.shareLinkButton.setImage(self.arrowUp?.changeAlpha(alpha: 1.0), for: .normal)
            self.loadingSpinner.isHidden = true
            self.loadingSpinner.stopAnimating()
            self.shareLinkButton.isEnabled = true
        }
    }
    
    @IBAction func shareLinkButtonTapped(_ sender: Any) {
        
        guard let shareURL = shareLink else { return }
        
        showShareMenu(url: shareURL)
    }
    
    
    func showShareMenu(url: URL) {
        
        let text = "Here's a link to send me £\(amountTextField.text!) with Wildfire"
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        present(activityVC, animated: true)
        
        Analytics.logEvent(Event.linkButtonTapped.rawValue, parameters: nil)
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
    
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        
        self.present(alert, animated: true)
    }
    
        @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    //        let sourceViewController = unwindSegue.source
            // Use data from the view controller which initiated the unwind segue
        }
    
}

