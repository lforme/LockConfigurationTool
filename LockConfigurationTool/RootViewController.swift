//
//  RootViewController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import PKHUD
import SnapKit

class RootViewController: UIViewController {
    
    fileprivate var loginVC: UINavigationController?
    fileprivate var rootTabbarVC: UITabBarController?
    
    fileprivate var _statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self._statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observerLoginStatus()
        observeStatusBarChanged()
        
    }
    
    
    private func showHomeTabbar() {
        loginVC?.view.removeFromSuperview()
        loginVC?.removeFromParent()
        loginVC = nil
        
        let tabBarVC = UITabBarController()
        
        let homeVC: HomeController = ViewLoader.Storyboard.controller(from: "Home")
        let homeTabbarItemNormal = UIImage(named: "home_normal_item")
        let homeTabbarItemSelect = UIImage(named: "home_select_item")
        
        
        let myVC: MyController = ViewLoader.Storyboard.controller(from: "My")
        let myTabbarItemNormal = UIImage(named: "my_normal_item")
        let myTabbarItemSelect = UIImage(named: "my_select_item")
        
        let tabItems: [(UIViewController, String, UIImage?, UIImage?)] = [
            (homeVC, "首页", homeTabbarItemNormal, homeTabbarItemSelect),
            (myVC, "我的", myTabbarItemNormal, myTabbarItemSelect)
        ]
        
        let navigationsVC = tabItems.map { (vc, title, normalIcon, selectIcon) -> UINavigationController in
            let item = UITabBarItem(title: title, image: normalIcon, selectedImage: selectIcon)
            
            item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : ColorClassification.primary.value, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)], for: .selected)
            vc.tabBarItem = item
            
            let navigationVC = UINavigationController(rootViewController: vc)
            return navigationVC
        }
        
        tabBarVC.viewControllers = navigationsVC
        
        self.rootTabbarVC = tabBarVC
        self.view.addSubview(rootTabbarVC!.view)
        self.addChild(rootTabbarVC!)
        
    }
    
    private func showLoginVC() {
        rootTabbarVC?.view.removeFromSuperview()
        rootTabbarVC?.removeFromParent()
        rootTabbarVC = nil
        
        let temp: LoginViewController = ViewLoader.Storyboard.controller(from: "Login")
        loginVC = UINavigationController(rootViewController: temp)
        self.view.addSubview(loginVC!.view)
        loginVC?.view.snp.makeConstraints({ (maker) in
            maker.edges.equalToSuperview()
        })
    }
    
    static func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}


/// 观察方法
extension RootViewController {
    
    func observeStatusBarChanged() {
        
        NotificationCenter.default.rx.notification(.statuBarDidChange)
            .takeUntil(rx.deallocated)
            .subscribeOn(MainScheduler.instance).subscribe(onNext: {[weak self] (noti) in
                if let style = noti.object as? UIStatusBarStyle {
                    self?._statusBarStyle = style
                }
            }).disposed(by: rx.disposeBag)
    }
    
    func observerLoginStatus() {
        
        LCUser.current().observedIsLogin
            .observeOn(MainScheduler.instance)
            .takeUntil(rx.deallocated)
            .subscribe(onNext: {[weak self] (isLogin) in
                //                if isLogin {
                //                    self?.showHomeTabbar()
                //                } else {
                //                    self?.showLoginVC()
                //                }
                self?.showHomeTabbar()
                }, onError: { (error) in
                    PKHUD.sharedHUD.rx.showError(error)
            })
            .disposed(by: rx.disposeBag)
    }
}
