//
//  PayViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import Contacts
import FirebaseCrashlytics
import FirebaseAnalytics
import Firebase

class PayViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElements()

    }

    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationItem.setHidesBackButton(false, animated: false)
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        
        Analytics.logEvent("test3_sendTapped", parameters: [EventVar.creditAdded.creditAmount.rawValue: EventVar.KYCUploaded.kycTypeOptions.IDCard.rawValue])
        
        CNContactStore().requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                self.universalShowAlert(title: "Error", message: "Something went wrong: \(error.localizedDescription)", segue: nil, cancel: false)
            } else {
                if granted == true {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "goToSend", sender: self)
                    }
                } else {
                    self.universalShowAlert(title: "Permission required", message: "Access to contact list is required to send payments.", segue: nil, cancel: false)
                }
            }
        }
                    
        
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
////        addRectAndWhiteOpenSans(title: " PAY ")
////        navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
    
    @IBAction func unwindToPay(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }

    
    func setUpElements() {
        
        Utilities.styleHollowButton(sendButton)
        Utilities.styleHollowButton(scanButton)
        

//        gradientBackground()
        
//        backgroundGradientView.layer.addSublayer(gradientLayer)
        
//        guard let icon = UIImage(named: "icons8-paper-plane-50") else { return }
//        sendButton.setImage(icon, for: .normal)
//        sendButton.imageView?.contentMode = .scaleAspectFit
////        sendButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
//        sendButton.
    }
    
    
    func gradientBackground() {
        // Create a gradient layer
        let gradientLayer = CAGradientLayer()
        // Set the size of the layer to be equal to size of the display
        gradientLayer.frame = view.bounds
        // Set an array of Core Graphics colors (.cgColor) to create the gradient
        gradientLayer.colors = [Style.secondaryThemeColour.cgColor, Style.secondaryThemeColourHighlighted.cgColor]

//        gradientLayer.locations = [0.0, 0.35]
        // Rasterize this static layer to improve app performance
        gradientLayer.shouldRasterize = true
        // Apply the gradient to the backgroundGradientView
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
//    @IBAction func launchQRReader(_ sender: UIButton) {
//
//    // the QR code needs to go here?
//    }

//    @IBAction func unwindToPayViewController(segue: UIStoryboardSegue) {
//    }
//    
}

