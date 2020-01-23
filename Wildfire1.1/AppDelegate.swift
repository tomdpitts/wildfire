//
//  AppDelegate.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 12/01/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import FirebaseCore
import LocalAuthentication
import FirebaseAuth
import FirebaseFunctions
import SwiftyJSON
import FBSDKCoreKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var timestamp: Int64?
    
    lazy var functions = Functions.functions(region:"europe-west1")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        // one for later
//        let db = Firestore.firestore()
        FBSDKApplicationDelegate.sharedInstance()?.application(application, didFinishLaunchingWithOptions: launchOptions)
        
//        // used to store profile pic cache key across sessions, to save from having to download it again from Storage
//        let defaults = UserDefaults.standard
//        let defaultValue = ["profilePicCacheKey": ""]
//        defaults.register(defaults: defaultValue)
        
        // check whether the user has completed signup flow 
        if UserDefaults.standard.bool(forKey: "userAccountExists") != true {
            Utilities().checkForUserAccount()
        }
        fetchPaymentMethodsListFromMangopay()
        redirect()
        return true
    }
    
    // this is a facebook-specific function required for compatibility with older iOS versions (<9.0 afaik)
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        self.timestamp = Date().toSeconds()
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        fetchPaymentMethodsListFromMangopay()
        redirect()
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func redirect() {
        
        // TODO if no connectivity, prevent user from progressing
        
        // check if they are logged in already
        let uid = Auth.auth().currentUser?.uid
        print(uid)
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        if uid != nil {
            if let checkoutTime = self.timestamp {
                if checkoutTime > Date().toSeconds() - 2 {
                    
                    
                    let initialViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "mainMenu") as UIViewController
                    self.window = UIWindow(frame: UIScreen.main.bounds)
                    self.window?.rootViewController = initialViewController
                    self.window?.makeKeyAndVisible()
                    
                } else {
                    
                    let initialViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeVC") as UIViewController
                    self.window = UIWindow(frame: UIScreen.main.bounds)
                    self.window?.rootViewController = initialViewController
                    self.window?.makeKeyAndVisible()
                    
                }
            } else {
                
                let initialViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeVC") as UIViewController
                self.window = UIWindow(frame: UIScreen.main.bounds)
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()
                
            }
            
        } else {
            let initialViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "verifyMobile") as UIViewController
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            
        }
    }
    
    func fetchPaymentMethodsListFromMangopay() {
        print("trying to fetch cards")
        functions.httpsCallable("listCards").call() { (result, error) in

            if let cardList = result?.data as? [[String: Any]] {
                let defaults = UserDefaults.standard
                
                defaults.set(cardList.count, forKey: "numberOfCards")
                
                let count = cardList.count
                
                if count > 0 {
                    for i in 1...count {
                        var cardNumber = ""
                        var cardProvider = ""
                        var expiryDate = ""
                        
                        let blob1 = cardList[i-1]
                        if let cn = blob1["Alias"] as? String, let cp = blob1["CardProvider"] as? String, let ed = blob1["ExpirationDate"] as? String {
                            
                            cardNumber = String(cn.suffix(8))
                            cardProvider = cp
                            expiryDate = ed
                        }
                        let card = PaymentCard(cardNumber: cardNumber, cardProvider: cardProvider, expiryDate: expiryDate)
                        
                        defaults.set(try? PropertyListEncoder().encode(card), forKey: "card\(i)")
                    }
                }
                
            } else {
                print("nope")
            }
        }
    }
}

extension Date {
    func toSeconds() -> Int64! {
        return Int64(self.timeIntervalSince1970)
    }
}

