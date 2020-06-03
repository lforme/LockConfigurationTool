//
//  AppearanceAppDelegate.swift
//  LightSmartLock
//
//  Created by mugua on 2020/5/22.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import IQKeyboardManager
import PKHUD
import ChameleonFramework
import SwiftDate

final class AppearanceAppDelegate: AppDelegateType {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        setupNetworkEnvironment()
        setupKeyborad()
        setupHUD()
        setupNavigationStyle()
        setupDateTime()
        
        return true
    }
    
    private func setupNetworkEnvironment() {
        ServerHost.shared.environment = .dev
    }
    
    private func setupKeyborad() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        IQKeyboardManager.shared().shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared().isEnableAutoToolbar = false
    }
    
    private func setupDateTime() {
        SwiftDate.defaultRegion = Region.current
    }
    
    private func setupHUD() {
        HUD.dimsBackground = false
        HUD.allowsInteraction = true
    }
    
    private func setupNavigationStyle() {
        
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.clear], for: UIControl.State())
    
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().barTintColor = ColorClassification.tableViewBackground.value
        UINavigationBar.appearance().tintColor = ColorClassification.textPrimary.value
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: ColorClassification.textPrimary.value,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28, weight: .black)
        ]
    }
}
