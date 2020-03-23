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

struct Style {
    
    // default values
    static var primaryThemeColour = UIColor(hexString: "#39C3C6")
    static var primaryThemeColourHighlighted = UIColor(hexString: "#39C3C6")
    
    static var black = UIColor(hexString: "#000000")
    static var secondaryThemeColour = UIColor(hexString: "#12263e")
    static var secondaryThemeColourHighlighted = UIColor(hexString: "#2c5b94")
    
    
    
    static var headerColour = UIColor(hexString: "#250B0B")
    static var bodyColour = UIColor(hexString: "#F1FBFB")
    
    static var sectionHeaderTitleColour = UIColor(hexString: "#F1FBFB")
    static var sectionHeaderTitleFont = UIFont(name: "System", size: 17)
    static var sectionHeaderAlpha: CGFloat = 1.0
    
    // not in use now, but leaving for future reference
    static func alternativeTheme1() {
        
        primaryThemeColour = UIColor(hexString: "#39C3C6")
        primaryThemeColourHighlighted = UIColor(hexString: "#39C3C6")
        
        secondaryThemeColour = UIColor(hexString: "#C63C39")
        secondaryThemeColourHighlighted = UIColor(hexString: "#C63C39")
        
        sectionHeaderTitleColour = UIColor(hexString: "#F1FBFB")
        sectionHeaderTitleFont = UIFont(name: "System", size: 17)
        sectionHeaderAlpha = 1.0
        
    }
}

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
    let currency: String
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
    let cardID: String
    let cardNumber: String
    let cardProvider: String
    let expiryDate: String
//    let icon: UIImage?
    
    // this simply translates MangoPay's     naming system to our (clearer) system
    enum CodingKeys: String, CodingKey {
        case cardID
        case cardNumber = "Alias"
        case cardProvider = "CardProvider"
        case expiryDate = "ExpirationDate"
    }
}

struct BankAccount: Codable {
    let accountHolderName: String
    let type: String
    let IBAN: String?
    let SWIFTBIC: String?
    let accountNumber: String?
    let country: String?
    
    // this simply translates MangoPay's naming system to our (clearer) system
    enum CodingKeys: String, CodingKey {
        case accountHolderName = "OwnerName"
        case type = "Type"
        case IBAN
        case SWIFTBIC = "BIC"
        case accountNumber = "AccountNumber"
        case country = "Country"
    }
}

//
//class Service {
//    static let baseColour = UIColor(r: 233, g: 233, b: 233)
//}

