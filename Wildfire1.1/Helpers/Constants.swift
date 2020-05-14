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

// this is Mangopay's list of countries they can't accept Users with Residency in
let blockedCountriesList = ["Afghanistan", "Bahamas", "Bosnia & Herzegovina", "Botswana", "Cambodia", "North Korea", "Ethiopia", "Ghana", "Guyana", "Iran", "Iraq", "Laos", "Uganda", "Pakistan", "Serbia", "Sri Lanka", "Syria", "Trinidad & Tobago", "Tunisia", "Vanuatu", "Yemen"]

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

enum Event: String {
    
    // Event Titles
    case QRScanned = "QRScanned"
    case paymentSuccess = "paymentSuccess"
    case receivedSuccess = "receivedSuccess"
    case accountAdded = "accountAdded"
    case paymentMethodAdded = "paymentMethodAdded"
    case paymentMethodDeleted = "paymentMethodDeleted"
    case bankAccountAdded = "bankAccountAdded"
    case bankAccountDeleted = "bankAccountDeleted"
    case KYCUploaded = "KYCUploaded"
    case KYCAccepted = "KYCAccepted"
    case KYCRejected = "KYCRejected"
    case creditAdded = "creditAdded"
    
}

enum EventVar {
    
    enum QRScanned: String {
        
        case scannedAmount = "scannedAmount"
        case scannedRecipient = "scannedRecipient"
    }
    
    enum paymentSuccess: String {
        
        case paidAmount = "paidAmount"
        case currency = "currency"
        case recipient = "recipient"
        case transactionType = "transactionType"
        case topup = "topup"
        
            enum transactionTypeOptions: String {
                // transactionType options
                case scan = "scan"
                case send = "send"
                case dynamicLink = "dynamicLink"
            }
    }
    
    enum receivedSuccess: String {
        
        case receivedAmount = "receivedAmount"
        case currency = "currency"
        
    }
    
    enum paymentMethodAdded: String {
        
        case paymentMethodType = "paymentMethodType"
        
        // paymentMethodAdded options
           enum paymentMethodTypeOptions: String {
               case card = "card"
               case paypal = "paypal"
               case other = "other"
           }
    }
    
    enum paymentMethodDeleted: String {
        
        case paymentMethodType = "paymentMethodType"
        
        // paymentMethodAdded options
           enum paymentMethodTypeOptions: String {
               case card = "card"
               case paypal = "paypal"
               case other = "other"
           }
    }
   
    
    enum KYCUploaded: String {
        // Event: KYCUploaded
        case kycType = "KYCType"
        
            enum kycTypeOptions: String {
                // kycType options
                case passport = "passport"
                case driverLicence = "driverLicence"
                case IDCard = "IDCard"
                case other = "other"
            }
    }
    
    enum creditAdded: String {
        // Event: creditAdded
        case creditAmount = "creditAmount"
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
        case cardID = "Id"
        case cardNumber = "Alias"
        case cardProvider = "CardProvider"
        case expiryDate = "ExpirationDate"
    }
}

// current fetchBankAccounts func in AppDelegate fills fields with empty strings if they're empty - these don't technically need to be optional but it feels like better practice
struct BankAccount: Codable {
    let accountID: String
    let accountHolderName: String
    let type: String
    let IBAN: String?
    let SWIFTBIC: String?
    let accountNumber: String?
    let sortCode: String?
    let country: String?
    
    // this simply translates MangoPay's naming system to our (better) system
    enum CodingKeys: String, CodingKey {
        case accountID = "Id"
        case accountHolderName = "OwnerName"
        case type = "Type"
        case IBAN
        case SWIFTBIC = "BIC"
        case accountNumber = "AccountNumber"
        case sortCode = "SortCode"
        case country = "Country"
    }
}

//
//class Service {
//    static let baseColour = UIColor(r: 233, g: 233, b: 233)
//}

