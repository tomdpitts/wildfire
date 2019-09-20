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
                print("vc side error")
            } else if let json = json {
                print(json.description)
                print("vc side json came back")
            }
        }
        
        
//        Alamofire.request("https://checkout-test.adyen.com/v49/paymentMethods", method: .post).responseJSON { (response) -> Void in
//            // Check if the result has a value
//            if let JSON = response.result.value {
//                print(JSON)
//            }
//        }
        
        
        
        
        
    }
    
    

}
