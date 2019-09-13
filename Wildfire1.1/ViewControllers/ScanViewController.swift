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
//import FirebaseDatabase

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    //setup topbar element
    @IBOutlet var topbar: UIView!
    
    //setup label element for testing
//    @IBOutlet weak var scannedNumber: UILabel!
    
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
//    var ref:DatabaseReference?
    
    //setup variable to retrieve and display account balance at all times
    var receivable: Int = 0
    var balance: Int = 0
    var finalString = ""
    
    
    var runScan = true

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ConfirmViewController
        vc.finalString2 = finalString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        var validatedString = ""
        
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
                validatedString = decryptQRString(QRstring: metadataObj.stringValue!)
                
                // now we know what the situation is, we can respond accordingly. If it's valid, segue to ConfirmViewController (check the prepareForSegue method in this VC for more context), otherwise do nothing and let the user continue scanning
                if validatedString == "decryption failed" {
                    return
                } else {
                    self.finalString = validatedString
//                    self.runScan == false
                    performSegue(withIdentifier: "showConfirmScreen", sender: self)
                    self.captureSession!.stopRunning()
                }
            }
        }
        
            
        }
    }
    
    func decryptQRString(QRstring: String) -> String {
        
        // this function could really do with some more nuanced error logging so we can find out what is causing decryption failure

        let encryptedArray = Array<UInt8>(hex: QRstring)
        
        // set up CryptoSwift object aes with the right key and initialization vector
        let aes = try? AES(key: "afiretobekindled", iv: "av3s5e12b3fil1ed")
        
        // try to decrypt the encryptedArray - if it's not a wildfire code and not formatted right this will probably break
        guard let decryptedArray = try? aes?.decrypt(encryptedArray) else {
            return "decryption failed"
        }
        
        // turn this into a string
        guard let decryptedString = String(bytes: decryptedArray, encoding: .utf8) else {
            return "decryption failed"
        }
        
        // now let's check it's legit - if it is, it will begin with the validator text. Theoretically, a QR code could contain something that can be decoded and handled by the above logic but the output would be gibberish e.g. a string encrypted with a different key - this validation checks that the result has come through as expected.
        let validator = """
        Einstein, James Dean, Brooklyn's got a winning team, Bardot, Budapest, Alabama, Krushchev
        """
        let validatorLength = validator.count
        
        // check the first 89 characters match the validator text, and if so, carry on and return the decrypted string. Otherwise abort and flag the issue to the user
        let billyJoel = String(decryptedString.prefix(validatorLength))
        if billyJoel == validator {
            let validatedString = String(decryptedString.dropFirst(validatorLength))
            return validatedString
        } else {
            return "decryption failed"
        }
    }

    
}



    

