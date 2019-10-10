//
//  LoginViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 22/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import AVKit
import FirebaseAuth
import FirebaseFirestore
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {

    var videoPlayer:AVPlayer?
    
    var videoPlayerLayer:AVPlayerLayer?
    
    private let readPermissions: [ReadPermission] = [ .publicProfile, .email]
    
    @IBOutlet weak var logInButton: UIButton!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var facebookButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpElements()
        
        // builds facebook button
        let buttonText = NSAttributedString(string: "Login with Facebook")
        facebookButton.setAttributedTitle(buttonText, for: .normal)
        facebookButton.titleLabel?.textAlignment = NSTextAlignment.center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Set up video in the background
        setUpVideo()
    }
    
    @IBAction func didTapFacebookButton(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: readPermissions, viewController: self, completion: didReceiveFacebookLoginResult)
    }
    
    private func didReceiveFacebookLoginResult(loginResult: LoginResult) {
        switch loginResult {
        case .success:
            didLoginWithFacebook()
        case .failed(_): break
        default: break
        }
    }
    
    fileprivate func didLoginWithFacebook() {
        // Successful log in with Facebook
        if let accessToken = AccessToken.current {
            // log the user into Firebase (if the user doesn't already exist, it is created automatically)
            FirebaseAuthManager().login(credential: FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)) {[weak self] (success) in
                
                // this weird line is to prevent memory leak: https://benscheirman.com/2018/09/capturing-self-with-swift-4-2/
                guard let self = self else { return }
                
                var message: String = ""
                if (success) {
                    message = "User was sucessfully logged in."
                } else {
                    message = "There was an error."
                }
                
                // pop up an alert to tell user the login was successful, or not
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                
                // user is already logged into Firebase, but we want to check if there's already a firestore doc for that user, and add one if not
                if let uid = Auth.auth().currentUser?.uid {
                    
                    let docRef = Firestore.firestore().collection("users").document(uid)
                    
                    docRef.getDocument { (document, error) in
                        // this if statement adds protection against accidentlly overwriting existing data
                        if let document = document, document.exists {
                            // user already exists so there's nothing further to do
                            return
                        } else {
                            // user doesn't yet exist, so we need to get the Facebook data into Firestore
                            self.getFacebookData()
                        }
                    }
                }
            }
        }
    }
    
    func getFacebookData() {
        let connection = GraphRequestConnection()
        connection.add(MyProfileRequest()) { response, result in
            switch result {
            case .success(let response):
                
                print("Custom Graph Request Succeeded: \(response)")
                let firstname = response.firstname
                let lastname = response.lastname
                let email = response.email
                let facebookID = response.id
                var photoURL = ""
                
                // this is the easiest way to access the Facebook profile pic (type options: small (50px), normal (100px), large (200px), square (?))
                if let fID = response.id {
                    photoURL = "http://graph.facebook.com/\(fID)/picture?type=large"
                }
            
                self.addDataToFirebase(firstname: firstname, lastname: lastname, email: email, photoURL: photoURL, facebookID: facebookID)
                
            case .failed(let error):
                print("Custom Graph Request Failed: \(error)")
            }
        }
        connection.start()
    }
    
    // this needs better error handling
    // note the merge: true parameter in the .setData as a safeguard against overwriting any existing data, although this func should only be called when there is no preexisting user record in Firestore
    func addDataToFirebase(firstname: String?, lastname: String?, email: String?, photoURL: String?, facebookID: String?) {
        if let firebaseID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(firebaseID).setData(["firstname": firstname ?? "", "lastname": lastname ?? "", "email": email ?? "", "balance": 0, "photoURL": photoURL ?? "", "facebookID": facebookID ?? ""], merge: true) { (error) in
                
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
        } else { return }
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
        
        // None of our movies should interrupt system music playback.
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default, options: .mixWithOthers)
        
        // Add it to the view and play it
        videoPlayer?.playImmediately(atRate: 1)
    }

    @IBAction func skipToPay(_ sender: Any) {
        performSegue(withIdentifier: "skipToPay", sender: self)
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    // this struct is a handy way to access facebook's graph api for facebook data
    struct MyProfileRequest: GraphRequestProtocol {
        struct Response: GraphResponseProtocol {
            var name: String?
            var firstname: String?
            var lastname: String?
            var id: String?
            var gender: String?
            var email: String?
            var profilePictureUrl: String?
            
            init(rawResponse: Any?) {
                // Decode JSON from rawResponse into other properties here.
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    return
                }
                
                if let name = response["name"] as? String {
                    self.name = name
                }
                
                if let firstname = response["first_name"] as? String {
                    self.firstname = firstname
                }
                
                if let lastname = response["last_name"] as? String {
                    self.lastname = lastname
                }
                
                if let id = response["id"] as? String {
                    self.id = id
                }
                
                if let email = response["email"] as? String {
                    self.email = email
                }
                
//                if let picture = response["picture"] as? Dictionary<String, Any> {
//
//                    if let data = picture["data"] as? Dictionary<String, Any> {
//                        if let url = data["url"] as? String {
//                            self.profilePictureUrl = url
//                        }
//                    }
//                }
            }
        }
        
        var graphPath = "/me"
        var parameters: [String : Any]? = ["fields": "id, first_name, last_name, email"]
        var accessToken = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
        
    }
    
    func setUpElements() {
        
        // Style the elements
        Utilities.styleFilledButton(logInButton)
        Utilities.styleFilledButton(signUpButton)
        //        Utilities.styleFilledButton(facebookButton)
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
