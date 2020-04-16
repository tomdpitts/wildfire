//
//  ScanViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

// Add an unwind/back button!

import UIKit
import AVFoundation
import CryptoSwift
import FirebaseFunctions
//import FirebaseDatabase

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    //setup topbar element
    @IBOutlet var topbar: UIView!
    
    //setup label element for testing
//    @IBOutlet weak var scannedNumber: UILabel!
    
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    @IBOutlet weak var cancelButton: UIButton!
    //    var ref:DatabaseReference?
    
    //setup variable to retrieve and display account balance at all times
    var receivable: Int = 0
    var balance: Int = 0
    var finalString = ""
    
    let validator = """
        Einstein, James Dean, Brooklyn's got a winning team, Bardot, Budapest, Alabama, Krushchev
        """
    // be careful - the validatorLength must be exactly correct
    let validatorLength = 89
    let multiplicationFactor = 7
    let UIDLength = 28
    
    var recipientUID: String?
    var sendAmount: Int?
    var currency: String?
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    var runScan = true

    @IBAction func dismissScan(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ConfirmViewController {
            let vc = segue.destination as! ConfirmViewController
//            vc.finalString2 = finalString
            if let uid = recipientUID, let send = sendAmount, let currency = currency {
                
                vc.recipientUID = uid
                vc.sendAmount = send
                vc.transactionCurrency = currency
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utilities.styleHollowButton(cancelButton)
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            
            appearance.configureWithDefaultBackground()
            
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            self.navigationController?.navigationBar.tintColor = .white
            self.navigationController?.navigationBar.isTranslucent = true
        }
        
//        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        self.navigationController!.navigationBar.shadowImage = UIImage()
       
//        self.navigationController?.navigationBar.backgroundColor = .clear

        
        
        // this func triggers Firestore balance to update from MangoPay - useful for the next screen when balance will be fetched
        self.functions.httpsCallable("getCurrentBalance").call(["foo": "bar"]) { (result, error) in
            if error != nil {
                // TODO error handling?
            } else {
                // nothing - happy days
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession = AVCaptureSession()
            captureSession!.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession!.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            videoPreviewLayer?.zPosition = -1
            view.layer.addSublayer(videoPreviewLayer!)
            
            
            // Start video capture.
            captureSession!.startRunning()
            
            // Move the message label and top bar to the front
            view.bringSubviewToFront(topbar)
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.blue.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
//                print("green box is live")
            }
            
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            // Check if the metadataObjects array is not nil and it contains at least one object.
        
        if runScan {
            
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero

            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then set the coloured square - we haven't yet established it's a Wildfire code but we know it's a QR code
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            // check there's something in the QR code
            if metadataObj.stringValue != nil {

                // decrypt the QR data - this will either return valid data or "decryption failed" if it's not a Wildfire code
                let QRRead = decryptQRString(QRstring: metadataObj.stringValue!)
                
                // now we know what the situation is, we can respond accordingly. If it's valid, segue to ConfirmViewController (check the prepareForSegue method in this VC for more context), otherwise do nothing and let the user continue scanning
                if QRRead == false {
                    return
                } else {
                    
                    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedbackgenerator.prepare()
                    impactFeedbackgenerator.impactOccurred()
                    
//                    self.finalString = validatedString
//                    self.runScan == false
                    performSegue(withIdentifier: "showConfirmScreen", sender: self)
                    self.captureSession!.stopRunning()
                }
            }
        }
        
            
        }
    }
    
    func decryptQRString(QRstring: String) -> Bool {
        
        // this function could really do with some more nuanced error logging so we can find out what is causing decryption failure

        let encryptedArray = Array<UInt8>(hex: QRstring)
        
        // set up CryptoSwift object aes with the right key and initialization vector
        let aes = try? AES(key: "afiretobekindled", iv: "av3s5e12b3fil1ed")
        
        // try to decrypt the encryptedArray - if it's not a wildfire code and not formatted right this will probably break
        guard let decryptedArray = try? aes?.decrypt(encryptedArray) else {
            return false
        }
        
        // turn this into a string
        guard let decryptedString = String(bytes: decryptedArray, encoding: .utf8) else {
            return false
        }
        
        // now let's check it's legit - if it is, it will begin with the validator text. Theoretically, a QR code could contain something that can be decoded and handled by the above logic but the output would be gibberish e.g. a string encrypted with a different key - this validation checks that the result has come through as expected.
        
        // check the first 89 characters match the validator text, and if so, carry on and return the decrypted string
        let billyJoel = String(decryptedString.prefix(self.validatorLength))
        if billyJoel == self.validator {
            let validatedString = String(decryptedString.dropFirst(self.validatorLength))
            
            // this function updates the class variables for recipientUID and sendAmount
            let extractedSuccessfully = extractQRData(QRString: validatedString)
            if extractedSuccessfully == true {
                return true
            } else {
                return false
            }
        } else {
            // TODO  could add logic here to show alert 'this is not a Wildfire code'
            return false
        }
    }
    
    func extractQRData(QRString: String) -> Bool {
        
        let uid = String(QRString.suffix(UIDLength))
        
        // extract the UID (at time of writing, last 28 characters
        self.recipientUID = uid
        let remaining = QRString.dropLast(UIDLength)
        
        // currency codes are always 3 characters long - extract that next
        let currency = String(remaining.suffix(3))
        self.currency = currency
        let amount = remaining.dropLast(3)
        
        // then extract the transaction amount i.e. how much the transaction is for. Be careful to allow for any number of digits - strip out the UID and currency code
        
        // safely unwrap the number which has been converted to Int from a string, and divide the number by 7 (in the ReceiveViewController, we multiplied the amount requested by 7 before adding it to the string. Simply another level of security that makes it harder to reverse engineer the QR generation - then someone couldn't even guess that the transaction amount is encoded somewhere in the QR string
        
        if let m = Int(amount) {
            self.sendAmount = m/self.multiplicationFactor
            return true
        } else {
            return false
        }
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
        //        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
}



    

