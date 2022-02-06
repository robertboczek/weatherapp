//
//  AppDelegate.swift
//  WeatherApp
//
//  Created by Robert Boczek on 11/18/19.
//  Copyright © 2019 Robert Boczek. All rights reserved.
//

import UIKit
import FBAudienceNetwork

import FBSDKLoginKit
import FBSDKShareKit
import FBSDKCoreKit

//import FacebookCore


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    var myViewController: ViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set the flag as true
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        // Set the flag as true
        FBAudienceNetwork.FBAdSettings.setAdvertiserTrackingEnabled(true);
        
        // Override point for customization after application launch.
        //FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Set the flag as true
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        // Set the flag as true
        FBAudienceNetwork.FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            options: options
        )
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
         print("Reloading the view...")
        
        //AppEvents.activateApp();
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
         print("Became active")

         //AppEvents.activateApp()
         myViewController?.reloadView()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Entering background")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("Resigning active")
    }

}

