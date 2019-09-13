//
//  ConfirmViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 11/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import CryptoSwift

class ConfirmViewController: UIViewController {
    
    var readStringConfirm = ""
    var decryptedString = ""
    var receiveAmount = ""
    var transactionAmountFinal = 0
    let UIDLength = 28
    let multiplicationFactor = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // first decrypt the QR data
        decryptedString = decryptQRString(QRstring: readStringConfirm)
        
        // then extract the UID (at time of writing, last 28 characters
        let uidParsed = String(decryptedString.suffix(UIDLength))
        
        // then extract the transaction amount i.e. how much the transaction is for. Be careful to allow for any number of digits - strip out the UID
        let transactionAmount = Int(decryptedString.dropLast(UIDLength))
        print(transactionAmount ?? "not sure what the number is")
        // safely unwrap the number which has been converted to Int from a string, and divide the number by 7 (in the ReceiveViewController, we multiplied the amount requested by 7 before adding it to the string. Simply another level of security that makes it harder to reverse engineer the QR generation - then someone couldn't even guess that the transaction amount is encoded somewhere in the QR string
        if let transactionAmountReal = transactionAmount {
            transactionAmountFinal = transactionAmountReal/multiplicationFactor
        } else {
            transactionAmountFinal = 0
        }
        // now we have, in transactionAmountFinal... the final amount
        receiveAmount = String(transactionAmountFinal)
        
        QROutput.text = uidParsed
        amountLabel.text = receiveAmount

        // Do any additional setup after loading the view.
    }
    

    @IBOutlet weak var QROutput: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBAction func backButton(_ sender: Any) {
    }
    
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

}
