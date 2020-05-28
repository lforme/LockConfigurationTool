//
//  AppDelegate.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/27.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    struct AppDelegateFactory {
        
        static func makeDefault() -> AppDelegateType {
            return CompositeAppDelegate(appDelegates: [
                AppearanceAppDelegate()
                ]
            )
        }
    }
    
    private let appDelegate = AppDelegateFactory.makeDefault()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        _ = appDelegate.application?(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        appDelegate.applicationDidBecomeActive?(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        appDelegate.applicationDidEnterBackground?(application)
    }
}

extension AppDelegate {
    
    static func changeStatusBarStyle(_ style: UIStatusBarStyle) {
        NotificationCenter.default.post(name: .statuBarDidChange, object: style)
    }
}

