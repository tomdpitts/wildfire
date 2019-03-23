//
//  ScanViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseDatabase

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    //setup topbar element
    @IBOutlet var topbar: UIView!
    
    //setup label element for testing
    @IBOutlet weak var scannedNumber: UILabel!
    
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var ref:DatabaseReference?
    
    //setup variable to retrieve and display account balance at all times
    var receivable: Int = 0
    var balance: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        ref?.child("accounts/1001").observeSingleEvent(of: .childAdded, with: { (snapshot) in
            self.balance = snapshot.value! as! Int
            print(self.balance)
        })
        
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
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
                print("green box is live")
            }
            
            
            
            
            
            
            
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            // Check if the metadataObjects array is not nil and it contains at least one object.
            print("we have liftoff")
            
            if metadataObjects.count == 0 {
                qrCodeFrameView?.frame = CGRect.zero
                print("nope")
                //messageLabel.text = "No QR code is detected"
                return
            }
            
            // Get the metadata object.
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            
            
            if metadataObj.type == AVMetadataObject.ObjectType.qr {
                // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
                qrCodeFrameView?.frame = barCodeObject!.bounds
                // print("ok, we're getting somewhere")
                if metadataObj.stringValue != nil {
                    // print("yeah")
                    print(metadataObj.stringValue!)
                    view.bringSubviewToFront(scannedNumber)
                    scannedNumber.text = metadataObj.stringValue!
                    
                    self.receivable = Int(metadataObj.stringValue!)!
                    
                    print(receivable)
                    
                    updateBalance(transaction: receivable)
                    
                }
            }
        }
    
    
    
    // Below is all for testing the firebase write functions
    var accountID: Int = 1001
    var payValue: Int = 0
    
    // To do: recplace the observeSingleEvent with a childChanged listener which will allow the balance variable to be up to date during scanning
    // this function currently just sums the existing balance and the transaction amount and replaces the account balance with this new integer, but in future it needs to be able to reduce the payer's balance by the appropriate amount and increase the recipient's account by the same. Account ID needs to be contained in the AR, so some kind of parsing function will be required to interpret the string read from the QR. The receive view controller will need to be updated too, and some thought should be given to the format of the string. Consider integrating cryptography to both, as will be required at some point. You'll also need to figure out how the account numbers are going to be structured.
    func updateBalance(transaction: Int) -> Int {
        
        let newBalance = balance + transaction
        
        ref?.child("accounts/1001/").updateChildValues(["Balance": newBalance])
        //ref?.child("Transactions").childByAutoId().setValue("datetime")
        return 1
    }
    
}
    
   /* @IBAction func payFiver(_ sender: Any){
    
        payValue += 5
        // updateBalance() */

    
    

    

