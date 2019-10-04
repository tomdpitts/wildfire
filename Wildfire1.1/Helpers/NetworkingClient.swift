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
    
    typealias WebServiceResponse = (String, Error?) -> Void
    
    func postCardInfo(url: URL, parameters: [String: String], completion: @escaping WebServiceResponse) {
        

//        let headers: HTTPHeaders = [
//            "API-key": "exampleAPIkey",
//            "content-type": "application/json"
//        ]
        Alamofire.request(url, method: .post, parameters: parameters).validate().responseString(completionHandler: { response in
            if let error = response.error {
                completion("nil", error)
            } else if let dataString = response.result.value {
                completion(dataString, nil)
            }
        })
        return
    }
    
    func getCardReg(url: URL, completion: @escaping (Data, Error?) -> Void) {
        
        
        //        let headers: HTTPHeaders = [
        //            "API-key": "exampleAPIkey",
        //            "content-type": "application/json"
        //        ]
        Alamofire.request(url, method: .get).validate().responseJSON(completionHandler: { response in
            if let error = response.error {
                completion(Data(), error)
            } else if let data = response.data {
                completion(data, nil)
            }
        })
        return
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
