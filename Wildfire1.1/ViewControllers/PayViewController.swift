//
//  PayViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit

class PayViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Pay"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setUpElements()
        
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func unwindToPay(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
//    // This next bit is supposed to stop the dang thing rotating in landscape mode, but doesn't seem to work
//    override open var shouldAutorotate: Bool {
//        return false
//    }
//
    
    func setUpElements() {
        
        Utilities.styleHollowButton(sendButton)
        Utilities.styleHollowButton(scanButton)
        

        gradientBackground()
//        backgroundGradientView.layer.addSublayer(gradientLayer)
    }
    
    
    func gradientBackground() {
         // Create a gradient layer.
         let gradientLayer = CAGradientLayer()
         // Set the size of the layer to be equal to size of the display.
         gradientLayer.frame = view.bounds
         // Set an array of Core Graphics colors (.cgColor) to create the gradient.
         // This example uses a Color Literal and a UIColor from RGB values.
         gradientLayer.colors = [UIColor(hexString:"#092c80").cgColor, UIColor(hexString: "#3f7fc0").cgColor]
         // Rasterize this static layer to improve app performance.
         gradientLayer.shouldRasterize = true
         // Apply the gradient to the backgroundGradientView.
        
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

