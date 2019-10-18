//
//  Constants.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 18/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import Foundation
//import LBTAComponents

struct Constants {
    
    struct Storyboard {
        
        static let homeViewController = "HomeVC"
    }
}

struct Contact {
    var givenName: String
    var familyName: String
    var fullName: String
    var phoneNumber: Int?
    var uid: String?
    
//    var initials: String {
//        return "\(givenName.first!)\(familyName.first!)"
//    }
}

struct Transaction {
    let amount: Int
    let contact: Contact
}


//
//class Service {
//    static let baseColour = UIColor(r: 233, g: 233, b: 233)
//}

