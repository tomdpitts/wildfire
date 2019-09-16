//
//  ConfirmViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreImage
import CryptoSwift
import Firebase


class ConfirmViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    var finalString2 = ""
    var decryptedString = ""
    var receiveAmount = ""
    var transactionAmountFinal = 0
    let UIDLength = 28
    let multiplicationFactor = 7
    var uidParsed = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setUpElements()
        recipientLabel.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        // first decrypt the QR data
//        decryptedString = decryptQRString(QRstring: finalString2)
        
        // then extract the UID (at time of writing, last 28 characters
        self.uidParsed = String(finalString2.suffix(UIDLength))
    
            // then extract the transaction amount i.e. how much the transaction is for. Be careful to allow for any number of digits - strip out the UID
            let transactionAmount = Int(finalString2.dropLast(UIDLength))
//            print(transactionAmount ?? "not sure what the number is")
        
            // safely unwrap the number which has been converted to Int from a string, and divide the number by 7 (in the ReceiveViewController, we multiplied the amount requested by 7 before adding it to the string. Simply another level of security that makes it harder to reverse engineer the QR generation - then someone couldn't even guess that the transaction amount is encoded somewhere in the QR string
            if let transactionAmountReal = transactionAmount {
                transactionAmountFinal = transactionAmountReal/multiplicationFactor
            } else {
                transactionAmountFinal = 0
            }
            // now we have, in transactionAmountFinal... the final amount
            receiveAmount = String(transactionAmountFinal)
        
        
        QROutput.text = uidParsed
        amountLabel.text = "£" + receiveAmount
        
        setUpRecipientDetails(uid: uidParsed)
        
        //        recipientImage.backgroundColour = Service.basecolour
        recipientImage.contentMode = .scaleAspectFill
        recipientImage.layer.cornerRadius = recipientImage.frame.size.height/2
        recipientImage.clipsToBounds = true
        

        // Do any additional setup after loading the view.
    }
    
    

    @IBOutlet weak var QROutput: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var recipientImage: UIImageView!
    
    
    
    
    // the encryption first concatenates the amount and the recipient's UID, then encrypts it with AES 128, then encodes the resulting data array into a Hex string which can easily be passed to the QR generator function
    // consequently, the decryption needs to unwind all of that in reverse order
    func decryptQRString(QRstring: String) -> String {
        
        let hexString = Array<UInt8>(hex: QRstring)
        
        // set up CryptoSwift object aes with the right key and initialization vector
        let aes = try? AES(key: "afiretobekindled", iv: "hdjajshdhxdgeehf")
        let aesData = try? aes?.decrypt(hexString)

        let decryptedString = String(bytes: aesData!, encoding: .utf8)
        
        // print("AES decrypted: \(String(describing: decryptedString))")
        return decryptedString ?? "decryption failed"
    }

    
//    func setUpElements() {
//
//        // Style the elements
//
//        Utilities.styleFilledButton(backButton)
//        Utilities.styleFilledButton(confirmButton)
//
//    }
    
    func setUpRecipientDetails(uid: String) {
        let uid = self.uidParsed
        let docRef = self.db.collection("users").document(uid)
        
//        var recipientFirstname = ""
//        var recipientLastname = ""
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                let recipientData = document.data()
                
                if let recipientImageURL = URL(string: recipientData?["photoURL"] as! String) {
                    self.recipientImage.load(url: recipientImageURL)
                    
                let recipientFirstname = recipientData?["firstname"] as! String
                print(recipientFirstname)
                let recipientLastname = recipientData?["lastname"] as! String
                
                
                self.recipientLabel.text = "to \(recipientFirstname) \(recipientLastname)"
                self.recipientLabel.alpha = 1
                
                    
                } else {
                    return
                }
                
                
            } else {
                print("Document does not exist")
            }
        }
        
//        docRef.getDocument { (document, error) in
//            if let city = document.flatMap({
//                $0.data().flatMap({ (data) in
//                    return City(dictionary: data)
//                })
//            }) {
//                print("City: \(city)")
//            } else {
//                print("Document does not exist")
//            }
//        }

        
    }
    
//    let profileImageViewHeight: CGFloat = 56
//    lazy var profileImageView: CachedImageView = {
//        var iv = CachedImageView()
//        iv.backgroundColour = Service.basecolour
//        iv.contentMode = .scaleAspectFill
//        iv.layer.cornerRadius = profileImageViewHeight/2
//        iv.clipsToBounds = True
//        return iv
//    }()
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
