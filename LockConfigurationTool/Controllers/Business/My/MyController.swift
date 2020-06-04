//
//  MyController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import RxCocoa
import Action
import PKHUD
import RxSwift

class MyController: UITableViewController, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.tableViewBackground.value
    }
    
    enum ActionType: Int {
        case changePassword = 0
    }
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "个人"
        setupUI()
        bind()
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
        logoutCell.preservesSuperviewLayoutMargins = false
        logoutCell.separatorInset = .init(top: 0, left: logoutCell.bounds.size.width, bottom: 0, right: 0)
        logoutCell.layoutMargins = .zero
    }
    
    func bind() {
        versionLabel.text = ServerHost.shared.environment.description
        
        let logoutAction = Action<Void?, Bool> { (tap) -> Observable<Bool> in
            
            if tap == nil {
                return .empty()
            }
            
            guard let token = LCUser.current().token?.accessToken else {
                return .error(AppError.reason("发生未知错误, token is nil."))
            }
            
            return AuthAPI.requestMapBool(.logout(token: token))
        }
        
        logoutButton.rx.tap.flatMapLatest {[unowned self] (_) in
            self.showActionSheet(title: "退出登录", message: "确定要退出登录吗?", buttonTitles: ["退出", "取消"], highlightedButtonIndex: 1)
        }.subscribe(onNext: { (index) in
            if index == 0 {
                logoutAction.execute(())
            }
        }).disposed(by: rx.disposeBag)
        
        logoutAction.errors.subscribe(onNext: { (error) in
            PKHUD.sharedHUD.rx.showActionError(error)
        }).disposed(by: rx.disposeBag)
        
        logoutAction.elements.subscribe(onNext: { (success) in
            if success {
                LCUser.current().logout()
            }
        }).disposed(by: rx.disposeBag)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch ActionType(rawValue: indexPath.row) {
            
        case .changePassword:
            ChangePasswordController.rx.present(from: self)
                .flatMapLatest { (arg) -> Observable<Bool> in
                    let oldPwd = arg.0
                    let newPwd = arg.1
                    return BusinessAPI.requestMapBool(.changePassword(oldPwd: oldPwd, newPwd: newPwd))
            }
            .subscribe(onNext: { (success) in
                if success {
                    HUD.flash(.label("修改密码成功"), delay: 2)
                }
            }, onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
            }).disposed(by: rx.disposeBag)
            
        default:
            break
        }
    }
}
