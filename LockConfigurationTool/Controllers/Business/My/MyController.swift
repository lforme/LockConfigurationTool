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

class MyController: UITableViewController {
    
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
        
        let logoutAction = Action<(), Bool> { (_) -> Observable<Bool> in
            
            guard let token = LCUser.current().token?.accessToken else {
                return .error(AppError.reason("发生未知错误, token is nil."))
            }
            
            return AuthAPI.requestMapBool(.logout(token: token))
        }
        
        logoutButton.rx.bind(to: logoutAction, input: ())
        
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
                .flatMapLatest { (newPassword) -> Observable<Bool> in
                    
                    guard var oldUser = LCUser.current().user else {
                        return .error(AppError.reason("发生未知错误, user is nil."))
                    }
                    oldUser.loginPassword = newPassword
                    return BusinessAPI.requestMapBool(.editUser(parameter: oldUser))
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
