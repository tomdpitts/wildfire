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

import mangopay




class PaymentSetupViewController: UIViewController {

    private let networkingClient = NetworkingClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    
    
    
    
    
//    @IBAction func refresh(_ sender: Any) {
//
//        guard let urlToExecute = URL(string: "https://checkout-test.adyen.com/v49/paymentMethods") else {
//            return
//        }
//        
//        networkingClient.executePost(url: urlToExecute) { (json, error) in
//
//            if let error = error {
//                print(error.localizedDescription)
//            } else if let json = json {
//                print(json.description)
//
//
//            }
//        }
//    }
    
    
    
    
    
    @IBAction func unwindToPaymentSetup(_ unwindSegue: UIStoryboardSegue) {
        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }

}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
