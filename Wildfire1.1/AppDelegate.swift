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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var timestamp: Int64?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        // one for later
//        let db = Firestore.firestore()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        self.timestamp = Date().toMillis()
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        guard let now = self.timestamp else { return }
        
        if Auth.auth().currentUser?.uid != nil {
            if now < Date().toMillis() - 10000 {
                
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let initialViewControlleripad : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeVC") as UIViewController
                self.window = UIWindow(frame: UIScreen.main.bounds)
                self.window?.rootViewController = initialViewControlleripad
                self.window?.makeKeyAndVisible()
            } else {
                return
            }
        } else {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewControlleripad : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "mainMenu") as UIViewController
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = initialViewControlleripad
            self.window?.makeKeyAndVisible()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

