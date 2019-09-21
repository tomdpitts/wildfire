//
//  PaymentSetupViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 19/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Adyen

class PaymentSetupViewController: UIViewController {

    private let networkingClient = NetworkingClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
//        Alamofire.request("https://codewithchris.com/code/afsample.json",
//                          method: .post
//            ).responseJSON { (response) -> Void in
//                // Check if the result has a value
//                if let JSON = response.result.value {
//                    print(JSON.self)
//                }
//        }
    
    
    
//    let headers: HTTPHeaders = [
//        "x-API-key": "AQErhmfuXNWTK0Qc+iSHm2g8oe2JTaZCA5ZTdHFSZ1WRrQy8iM0VodfLIVnUxhDBXVsNvuR83LVYjEgiTGAH-PWY69fb0dtWCj+QKskYg6tKOizhPv6FHusMsunK+16w=-u9PTbms23WcYZ6Q9",
//        "content-type": "application/json"
//    ]
//
//
//
//    struct Params: Encodable {
//        let email: String
//        let password: String
//    }
//
//    let param = Params(email: "test@test.test", password: "testPassword")
//
    
    
    @IBAction func refresh(_ sender: Any) {
        
        guard let urlToExecute = URL(string: "https://checkout-test.adyen.com/v49/paymentMethods") else {
            return
        }
        
        networkingClient.executePost(url: urlToExecute) { (json, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let json = json {
                print(json.description)
        
//                let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: paymentMethodsResponse)
//
//                let configuration = DropInComponent.PaymentMethodsConfiguration()
//                configuration.card.publicKey = "..." // Your public key, retrieved from the Customer Area.
//                // Check specific payment method pages to confirm if you need to configure additional required parameters.
//                // For example, to enable the Card form, you need to provide your Client Encryption Public Key.
//
//
//                let dropInComponent = DropInComponent(paymentMethods: paymentMethods,
//                                                      paymentMethodsConfiguration: configuration)
//                dropInComponent.delegate = self
//                dropInComponent.environment = .test
//                // When you're ready to go live, change this to .live
//                // or to other environment values described in https://adyen.github.io/adyen-ios/Docs/Structs/Environment.html
//                present(dropInComponent.viewController, animated: true)

            }
        }
        
        
    }
    
    

}
