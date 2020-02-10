//
//  Constants.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 18/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import Foundation
import UIKit
//import LBTAComponents

//class GlobalVariables {
//    var userAccountExists = false
//    var enoughCredit = false
//    var existingPaymentMethod = false
//}

struct Constants {
    
    struct Storyboard {
        
        static let homeViewController = "HomeVC"
    }
}

struct Contact {
    var givenName: String
    var familyName: String
    var fullName: String
    var phoneNumber: String?
    var uid: String?
}

struct Transaction: Codable {
    let amount: Int
    let currency: String?
    let datetime: Date
    let payerID: String
    let recipientID: String
    let payerName: String?
    let recipientName: String?
    let userIsPayer: Bool
    
    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case datetime
        case payerID
        case recipientID
        case payerName
        case recipientName
        case userIsPayer
    }
}

struct PaymentCard: Codable {
    let cardNumber: String
    let cardProvider: String
    let expiryDate: String
//    let icon: UIImage?
    
    // this simply translates MangoPay's naming system to our (clearer) system
    enum CodingKeys: String, CodingKey {
        case cardNumber = "Alias"
        case cardProvider = "CardProvider"
        case expiryDate = "ExpirationDate"
    }
}

//
//class Service {
//    static let baseColour = UIColor(r: 233, g: 233, b: 233)
//}

