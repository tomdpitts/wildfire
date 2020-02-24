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
        
        Utilities.styleHollowButton(btnAction)
        
        amountTextField.delegate = self
        amountTextField.keyboardType = .decimalPad
        // N.B. You need to make sure users can't copy and paste non numeric characters into field
        // which hasn't been added yet, only the textField type. If there's no actual field and
        // the numbers are all back end, I don't think there's any point adding it now.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        
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
            btnAction.setTitle("Clear",for: .normal)
            
        }
            
        else {
            // revert to empty state
            QRCodeImageView.image = nil
            qrcodeImage = nil
            btnAction.setTitle("Generate",for: .normal)
        }
    }
    
    func displayQRCodeImage() {
        
        let scaleX = QRCodeImageView.frame.size.width / qrcodeImage.extent.size.width
        let scaleY = QRCodeImageView.frame.size.height / qrcodeImage.extent.size.height
        
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        QRCodeImageView.image = UIImage(ciImage: transformedImage)
    }
    
    func generateQRString() -> String {
        
        var receiveAmountString = ""
        
        // validator is text that will be appended to the beginning of the string - this is a failsafe to essentially ensure that the decrypted string is from Wildfire (lyrics are not all in the right order)
        let validator = """
            Einstein, James Dean, Brooklyn's got a winning team, Bardot, Budapest, Alabama, Krushchev
            """
        
        if let receiveAmount = amountTextField.text {
            if let float = Float(receiveAmount) {
                print("converted to float")
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
        if let dotIndex = newText.index(of: ".") {
            numberOfDecimalDigits = newText.distance(from: dotIndex, to: newText.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }

        return isNumeric && numberOfDots <= 1 && numberOfDecimalDigits <= 2
    }  
}

