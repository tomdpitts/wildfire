//
//  AddCardViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 30/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseFunctions
import Alamofire
import SwiftyJSON

class AddCardViewController: UIViewController {
    
    var cardRegJSON: J
    

    @IBOutlet weak var resultField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    lazy var functions = Functions.functions(region:"europe-west1")
    
    
    
    @IBAction func addCard(_ sender: Any) {
    
    
        functions.httpsCallable("createPaymentMethodHTTPS").call(["text": "Euros"]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                }
                // ...
            }
            
            print(result ?? "can't print result")
    
            let json = JSON(result?.data ?? "no data returned")
            
            self.cardRegJSON = JSON(result?.data)
        
            print(json)
            
            
            
//            if let jsondata = (result?.data() as? [String: Any])? {
//                if let json = try? JSON(data: jsondata) {
//                    for item in json["people"].arrayValue {
//                        print(item["firstName"].stringValue)
//                    }
//                }
//            }
            
            }
        
        
        
        
        
        
        
        }
        
}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


