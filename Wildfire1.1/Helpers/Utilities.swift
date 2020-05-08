//
//  Utilities.swift
//
//  Created by Thomas Pitts on 26/08/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//


import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseInstanceID

class Utilities {
    
    // run check to see if user has set up their account i.e. completed the signup flow
    // this should run everytime user opens app while the value for key userAccountExists is false - thereafter we can ignore the func
    static func checkForUserAccount() {
        
        
        let db = Firestore.firestore()
        
        if let uid = Auth.auth().currentUser?.uid {
            let docRef = db.collection("users").document(uid)

            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    UserDefaults.standard.set(true, forKey: "userAccountExists")
//                    let userData = doc.data()
//
//                    // somewhat hacky, but fcmToken is now written to the user record in firebase, so can no longer use the document.exists test to determine whether or not the user has completed the signup flow
//                    if (userData?["email"]) != nil {
//                        UserDefaults.standard.set(true, forKey: "userAccountExists")
//                    } else {
//                        UserDefaults.standard.set(false, forKey: "userAccountExists")
//                    }
                } else {
                    UserDefaults.standard.set(false, forKey: "userAccountExists")
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "userAccountExists")
        }
    }
    
    static func checkForUserAccountWithCompletion(completion: @escaping ()->()) {
        let db = Firestore.firestore()
                
                if let uid = Auth.auth().currentUser?.uid {
                    let docRef = db.collection("users").document(uid)

                    docRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            UserDefaults.standard.set(true, forKey: "userAccountExists")
                            completion()
                        } else {
                            UserDefaults.standard.set(false, forKey: "userAccountExists")
                            completion()
                        }
                    }
                } else {
                    UserDefaults.standard.set(false, forKey: "userAccountExists")
                    completion()
                }
    }
    
    
    static func getMangopayID() {
        let db = Firestore.firestore()
        
        if let uid = Auth.auth().currentUser?.uid {
            let docRef = db.collection("users").document(uid)

            docRef.getDocument { (document, error) in
                
                if let document = document {
                    let ID = document["mangopayID"]
                    UserDefaults.standard.set(ID, forKey: "mangopayID")
                }
            }
        }
    }
    
    static func getCurrentRegistrationToken() {
        InstanceID.instanceID().instanceID { (result, error) in
            if error != nil {
                return
            } else if let result = result {

                // don't have time to test whether the rest of this func is required, or whether the didReceiveRegistrationToken method in AppDelegate is fired automatically. At worst, this process runs twice which shouldn't break anything.

                let fcmToken = result.token

                // update current saved token
                UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
                
                // we don't want to save the token to cloud just yet as it would trigger mangopay user creation before the required data is available. The fcmToken will be added to the user profile when user account is created

//                guard let uid = Auth.auth().currentUser?.uid else { return }
//
//                let tokenData = [
//                    "fcmToken": fcmToken
//                ]
//
//                Firestore.firestore().collection("users").document(uid).setData(tokenData, merge: true)
            }
        }
    }
    
    static func styleTextField(_ textfield:UITextField) {
        
        // Create the bottom line
        let bottomLine = CALayer()
        
        bottomLine.frame = CGRect(x: 0, y: textfield.frame.height - 2, width: textfield.frame.width, height: 2)
        
        bottomLine.backgroundColor = UIColor.init(red: 57/255, green: 195/255, blue: 198/255, alpha: 1).cgColor
        
        // Remove border on text field
        textfield.borderStyle = .none
        
        // Add the line to the text field
        textfield.layer.addSublayer(bottomLine)
        
    }
    
    static func styleLabel(_ label:UILabel) {
        
        // Create the bottom line
        let bottomLine = CALayer()
        
        bottomLine.frame = CGRect(x: 0, y: label.frame.height - 2, width: label.frame.width, height: 2)
        
        bottomLine.backgroundColor = UIColor.init(red: 57/255, green: 195/255, blue: 198/255, alpha: 1).cgColor
        
        // Add the line to the text field
        label.layer.addSublayer(bottomLine)
        
    }
    
    static func styleFilledButton(_ button:UIButton) {
        
        // Filled rounded corner style
        button.backgroundColor = UIColor(hexString: "#39C3C6")
        button.layer.cornerRadius = 20.0
        button.tintColor = UIColor.white
    }
    
    
    static func styleFilledButtonRED(_ button:UIButton) {
        
        // Filled rounded corner style
        // hex code for this colour is #39c3c6
        button.backgroundColor = UIColor(hexString: "#C63C39")
        button.layer.cornerRadius = 20.0
        button.tintColor = UIColor.white
    }
    
    static func styleHollowButton(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor(hexString: "#39C3C6").cgColor
        button.layer.cornerRadius = 25.0
        button.tintColor = UIColor.black
    }
    
    static func styleHollowButtonSELECTED(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor(hexString: "#aae5e7").cgColor
        button.layer.cornerRadius = 25.0
        button.tintColor = UIColor.black
    }
    
    static func styleHollowButtonRED(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor(hexString: "#C63C39").cgColor
        button.layer.cornerRadius = 25.0
        button.tintColor = UIColor.black
        
        let red = UIColor(hexString: "#C63C39")
        button.setTitleColor(red, for: UIControl.State.normal)
    }
    
    static func isPasswordValid(_ password : String) -> Bool {
        
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[0-9]).{8,}")
        return passwordTest.evaluate(with: password)
    }
    
//    static func isPasswordValid(_ password : String) -> Bool {
//
//        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
//        return passwordTest.evaluate(with: password)
//    }

    static func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let inverseSet = NSCharacterSet(charactersIn:"0123456789").inverted

        let components = string.components(separatedBy: inverseSet)

        let filtered = components.joined(separator: "")

        if filtered == string {
            return true
        } else {
            if string == "." {
                let countdots = textField.text!.components(separatedBy:".").count - 1
                if countdots == 0 {
                    return true
                } else {
                    if countdots > 0 && string == "." {
                        return false
                    } else {
                        return true
                    }
                }
            } else {
                return false
            }
        }
    }
    
    static func localeFinder(for fullCountryName : String) -> String? {
        
        for localeCode in NSLocale.isoCountryCodes {
            let identifier = NSLocale(localeIdentifier: "en_UK")
            let countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: localeCode)
            
            let countryNameClean = countryName!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let fullCountryNameClean = fullCountryName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if fullCountryNameClean == countryNameClean {
                return localeCode
            }
        }
        return nil
    }
    
    static func countryName(from countryCode: String) -> String {
        if let name = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: countryCode) {
            // Country name was found
            return name
        } else {
            // Country name cannot be found
            return countryCode
        }
    }
}

private var __maxLengths = [UITextField: Int]()

extension UITextField {
    @IBInspectable var maxLength: Int {
        get {
            guard let l = __maxLengths[self] else {
               return 150 // (global default-limit. or just, Int.max)
            }
            return l
        }
        set {
            __maxLengths[self] = newValue
            addTarget(self, action: #selector(fix), for: .editingChanged)
        }
    }
    @objc func fix(textField: UITextField) {
        let t = textField.text
        if let temp = t?.prefix(maxLength) {
            let temp2 = String(temp)
            textField.text = temp2
        }
    }
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }
        
        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0
        
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

class ImagePickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var picker = UIImagePickerController();
    var alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
    var viewController: UIViewController?
    var pickImageCallback : ((UIImage) -> ())?;
    
    override init(){
        super.init()
    }
    
    func pickImage(_ viewController: UIViewController, _ callback: @escaping ((UIImage) -> ())) {
        pickImageCallback = callback;
        self.viewController = viewController;
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default){
            UIAlertAction in
            self.openCamera()
        }
        let galleryAction = UIAlertAction(title: "Gallery", style: .default){
            UIAlertAction in
            self.openGallery()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){
            UIAlertAction in
        }
        
        // Add the actions
        picker.delegate = self
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = self.viewController!.view
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func openCamera(){
        alert.dismiss(animated: true, completion: nil)
        if(UIImagePickerController .isSourceTypeAvailable(.camera)){
            picker.sourceType = .camera
            self.viewController!.present(picker, animated: true, completion: nil)
        } else {
            // pop up an alert to tell user the login was successful, or not
            let alert = UIAlertController(title: nil, message: "Could not find camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alert.present(alert, animated: true)
            
        }
    }
    
    func openGallery(){
        alert.dismiss(animated: true, completion: nil)
        picker.sourceType = .photoLibrary
        self.viewController!.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
          fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        pickImageCallback?(image)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, pickedImage: UIImage?) {
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

var vSpinner : UIView?

extension UIViewController {
    
    func universalShowAlert(title: String, message: String?, segue: String?, cancel: Bool) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let seg = segue {
                    self.performSegue(withIdentifier: seg, sender: self)
                }
            }))

            if cancel == true {
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
            }
            
            self.present(alert, animated: true)
        }
    }
       
    func showSpinner(titleText: String?, messageText: String?) {
        
        var title = "Just a moment"
        var message = ""
        
        if let text = titleText {
            title = text
        }
        
        if let textM = messageText {
            message = textM
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func removeSpinner() {
        
        let presentedVC : UIViewController? = self.presentedViewController

        if presentedVC != nil {
            
            if let alertController: UIAlertController = presentedVC as? UIAlertController {
                
                DispatchQueue.main.async {
                    alertController.dismiss(animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    func removeSpinnerWithCompletion(spinnerCompletion: @escaping ()->()) {
        
        let presentedVC : UIViewController? = self.presentedViewController as UIViewController?

        if presentedVC != nil {
            
            if let alertController : UIAlertController = presentedVC as? UIAlertController {
                
                DispatchQueue.main.async {
                    alertController.dismiss(animated: true) {
                        spinnerCompletion()
                    }
                }
            } else {
                spinnerCompletion()
            }
        } else {
            spinnerCompletion()
        }
    }
    
    func addRectAndWhiteOpenSans(title: String) {

        // get screen size object.
        let screenSize: CGRect = UIScreen.main.bounds
        
        // get screen width.
        let screenWidth = screenSize.width
        
        // get screen height.
        let screenHeight = screenSize.height
        
        // the rectangle top left point x axis position.
        let xPos = 0
        let xPosLabel = 15
        
        // the rectangle top left point y axis position.
        let yPos = 40
        
        // the rectangle width.
        let rectWidth = Int(screenWidth) - 2 * xPos
        
        // the rectangle height.
        let rectHeight = 70
        
        // Create a CGRect object which is used to render a rectangle.
        let rectFrame: CGRect = CGRect(x:CGFloat(xPos), y:CGFloat(yPos), width:CGFloat(rectWidth), height:CGFloat(rectHeight))
        
        // Create a UIView object which use above CGRect object.
        let blackView = UIView(frame: rectFrame)
        
        // Set UIView background color.
        blackView.backgroundColor = UIColor.black
        
        let labelRectFrame: CGRect = CGRect(x:CGFloat(xPosLabel), y:CGFloat(0), width:CGFloat(rectWidth), height:CGFloat(rectHeight))
        
        let titleLabel = UILabel(frame: labelRectFrame)
        
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "OpenSans-ExtraBoldItalic", size: 52)
        titleLabel.backgroundColor = .black
        titleLabel.textAlignment = NSTextAlignment.left
        
        blackView.addSubview(titleLabel)
        
//        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "OpenSans-ExtraBoldItalic", size: 36)!]
//        navigationController?.navigationBar.largeTitleTextAttributes = attributes
        
//        self.navigationController?.navigationBar.insertSubview(blackView, at: 0)
        self.view.addSubview(blackView)
    }
    
//    func revertToBlackOpenSans() {
//        let largeTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkText, NSAttributedString.Key.font: UIFont(name: "OpenSans-ExtraBoldItalic", size: 36)!]
//        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkText, NSAttributedString.Key.font: UIFont(name: "OpenSans-ExtraBoldItalic", size: 26)!]
//
//        navigationController?.navigationBar.titleTextAttributes = normalTextAttributes
//        navigationController?.navigationBar.largeTitleTextAttributes = largeTextAttributes
//    }
}

// this extension helps with debugging layout conflicts and issues
extension NSLayoutConstraint {

    override public var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" //you may print whatever you want here
    }
}

// used to set alpha of an image
extension UIImage {
    func changeAlpha(alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

// One to come back to perhaps:
//    func gradientBackground() {
//        // Create a gradient layer
//        let gradientLayer = CAGradientLayer()
//        // Set the size of the layer to be equal to size of the display
//        gradientLayer.frame = view.bounds
//        // Set an array of Core Graphics colors (.cgColor) to create the gradient
//        gradientLayer.colors = [Style.secondaryThemeColour.cgColor, Style.secondaryThemeColourHighlighted.cgColor]
//
////        gradientLayer.locations = [0.0, 0.35]
//        // Rasterize this static layer to improve app performance
//        gradientLayer.shouldRasterize = true
//        // Apply the gradient to the backgroundGradientView
//        self.view.layer.insertSublayer(gradientLayer, at: 0)
//    }

//class GradientView: UIView {
//
//    /* Overriding default layer class to use CAGradientLayer */
//    override class var layerClass: AnyClass {
//        return CAGradientLayer.self
//    }
//
//    /* Handy accessor to avoid unnecessary casting */
//    private var gradientLayer: CAGradientLayer {
//        return layer as! CAGradientLayer
//    }
//
//    /* Public properties to manipulate colors */
//    public var fromColor: UIColor = UIColor.red {
//        didSet {
//            var currentColors = gradientLayer.colors
//            currentColors![0] = fromColor.cgColor
//            gradientLayer.colors = currentColors
//        }
//    }
//
//    public var toColor: UIColor = UIColor.blue {
//        didSet {
//            var currentColors = gradientLayer.colors
//            currentColors![1] = toColor.cgColor
//            gradientLayer.colors = currentColors
//        }
//    }
//
//    /* Initializers overriding to have appropriately configured layer after creation */
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        gradientLayer.colors = [fromColor.cgColor, toColor.cgColor]
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        gradientLayer.colors = [fromColor.cgColor, toColor.cgColor]
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
//    }
//}

//class UINavigationBarGradientView: UIView {
//
//    enum Point {
//        case topRight, topLeft, top
//        case bottomRight, bottomLeft, bottom
//        case custion(point: CGPoint)
//
//        var point: CGPoint {
//            switch self {
//                case .topRight: return CGPoint(x: 1, y: 0)
//                case .topLeft: return CGPoint(x: 0, y: 0)
//                case .top: return CGPoint(x: 0.5, y: 0)
//                case .bottomRight: return CGPoint(x: 1, y: 1)
//                case .bottomLeft: return CGPoint(x: 0, y: 1)
//                case .bottom: return CGPoint(x:0.5, y: 1)
//                case .custion(let point): return point
//            }
//        }
//    }
//
//    private weak var gradientLayer: CAGradientLayer!
//    convenience init(colors: [UIColor], startPoint: Point = .topLeft,
//                     endPoint: Point = .bottomLeft, locations: [NSNumber] = [0, 1]) {
//        self.init(frame: .zero)
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = frame
//        layer.addSublayer(gradientLayer)
//        self.gradientLayer = gradientLayer
//        set(colors: colors, startPoint: startPoint, endPoint: endPoint, locations: locations)
//        backgroundColor = .clear
//    }
//
//    func set(colors: [UIColor], startPoint: Point = .topLeft,
//             endPoint: Point = .bottomLeft, locations: [NSNumber] = [0, 1]) {
//        gradientLayer.colors = colors.map { $0.cgColor }
//        gradientLayer.startPoint = startPoint.point
//        gradientLayer.endPoint = endPoint.point
//        gradientLayer.locations = locations
//    }
//
//    func setupConstraints() {
//        guard let parentView = superview else { return }
//        translatesAutoresizingMaskIntoConstraints = false
//        topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
//        leftAnchor.constraint(equalTo: parentView.leftAnchor).isActive = true
//        parentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
//        parentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        guard let gradientLayer = gradientLayer else { return }
//        gradientLayer.frame = frame
//        superview?.addSubview(self)
//    }
//}
//
//extension UINavigationBar {
//    func setGradientBackground(colors: [UIColor],
//                               startPoint: UINavigationBarGradientView.Point = .topLeft,
//                               endPoint: UINavigationBarGradientView.Point = .bottomLeft,
//                               locations: [NSNumber] = [0, 1]) {
//        guard let backgroundView = value(forKey: "backgroundView") as? UIView else { return }
//        guard let gradientView = backgroundView.subviews.first(where: { $0 is UINavigationBarGradientView }) as? UINavigationBarGradientView else {
//            let gradientView = UINavigationBarGradientView(colors: colors, startPoint: startPoint,
//                                                           endPoint: endPoint, locations: locations)
//            backgroundView.addSubview(gradientView)
//            gradientView.setupConstraints()
//            return
//        }
//        gradientView.set(colors: colors, startPoint: startPoint, endPoint: endPoint, locations: locations)
//    }
//}

