//
//  NetworkingClient.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 20/09/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class NetworkingClient {
    
    typealias WebServiceResponse = ([String: Any]?, Error?) -> Void
    
    func executePost(url: URL, completion: @escaping WebServiceResponse) {
        

        let headers: HTTPHeaders = [
            "x-API-key": "AQErhmfuXNWTK0Qc+iSHm2g8oe2JTaZCA5ZTdHFSZ1WRrQy8iM0VodfLIVnUxhDBXVsNvuR83LVYjEgiTGAH-gPu+FjFNLazaK3XppEhZY2AQ5R9dXvCtSSaVgr6sxLw=-WTkh6PxX2yKaqQZe",
            "content-type": "application/json"
        ]
        
        
        let body: [String: Any] = [
            "merchantAccount": "WildfireMoneyLtdECOM",
            "countryCode": "NL",
            "amount": [
                    "currency" : "EUR",
                    "value": 1000
            ],
            "channel": "iOS"
        ]
        
//        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
            if let error = response.error {
                completion(nil, error)
//            } else if let jsonArray = response.result.value as? [[String:Any]] {
//                completion(jsonArray, nil)
            } else if let jsonDict = response.result.value as? [String: Any] {
                completion(jsonDict, nil)

            }
        }
    }

    // vanilla template
//    func execute(_ url: URL, completion: @escaping WebServiceResponse) {
//        Alamofire.request(url).validate().responseJSON { response in
//            if let error = response.error {
//                completion(nil, error)
//            } else if let jsonArray = response.result.value as? [[String:Any]] {
//                completion(jsonArray, nil)
//            } else if let jsonDict = response.result.value as? [String: Any] {
//                completion([jsonDict], nil)
//            }
//        }
//    }
}
