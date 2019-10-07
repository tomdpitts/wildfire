//
//  LoginViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import AVKit
import FirebaseUI


class LoginViewController: UIViewController {

    var videoPlayer:AVPlayer?
    
    var videoPlayerLayer:AVPlayerLayer?
    
    @IBOutlet weak var logInButton: UIButton!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpElements()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Set up video in the background
        setUpVideo()
    }

    func setUpElements() {
        
        // Style the elements
        Utilities.styleFilledButton(logInButton)
        Utilities.styleFilledButton(signUpButton)
        
    }
    
    
    func setUpVideo() {
        
        // Get the path to the resource in the bundle
        let bundlePath = Bundle.main.path(forResource: "WildfireLogin", ofType: "mp4")
        
        guard bundlePath != nil else {
            return
        }
        
        // Create a URL from it
        let url = URL(fileURLWithPath: bundlePath!)
        
        // Create the video player item
        let item = AVPlayerItem(url: url)
        
        // Create the player
        videoPlayer = AVPlayer(playerItem: item)
        
        // Create the layer
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer!)
        
        // Adjust the size and frame
        videoPlayerLayer?.frame = CGRect(x: -self.view.frame.size.width*1.5, y: 0, width: self.view.frame.size.width*4, height: self.view.frame.size.height)
        
        view.layer.insertSublayer(videoPlayerLayer!, at: 0)
        
        // Add it to the view and play it
        videoPlayer?.playImmediately(atRate: 1)
    }

    @IBAction func skipToPay(_ sender: Any) {
        performSegue(withIdentifier: "skipToPay", sender: self)
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
//  DEPRECATED
    
//  @IBAction func loginButtonTapped(_ sender: UIButton) {
//
//        // get the default auth UI object
//        let authUI = FUIAuth.defaultAuthUI()
//
//        guard authUI != nil else {
//            // Log the error
//            return
//        }
//        // Set ourselves as the delegate
//        authUI?.delegate = self
//
//        // get a reference to the auth UI view controller
//        let authViewController = authUI!.authViewController()
//
//        // Show it
//        present(authViewController, animated: true, completion: nil)
//    }
//
//}
//
//extension LoginViewController: FUIAuthDelegate {
//
//    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
//
//        // check for errors
//        guard error == nil else {
//            // log error
//            return
//        }
//
//        // authDataResult?.user.uid
//        // I've disconnected the seque so goHome doesn't exist - reconnect!
//        performSegue(withIdentifier: "goHome", sender: self)
//    }
}
