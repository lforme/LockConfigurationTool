//
//  TaskDetailController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/3.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import PKHUD

class TaskDetailController: UITableViewController, NavigationSettingStyle {
    
    enum EditType {
        case addNew
        case modify
    }
    
    var backgroundColor: UIColor? {
        return ColorClassification.navigationBackground.value
    }
    
    var originalModel: ConfigureTaskListModel?
    
    @IBOutlet weak var snTextField: UITextField!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var bindLockButton: UIButton!
    
    var vm: TaskDetailViewModel!
    var type: EditType!
    
    deinit {
        print("\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "配置详情"
        setupUI()
        bind()
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        view.backgroundColor = ColorClassification.viewBackground.value
        
        if originalModel?.isOnlineNo == .some(.configured) {
            bindLockButton.isHidden = true
            snTextField.isEnabled = false
            phoneTextField.isEnabled = false
            addressTextField.isEnabled = false
            scanButton.isEnabled = false
        }
    }
    
    func bind() {
        
        vm = TaskDetailViewModel(type: self.type, model: self.originalModel)
        
        if let model = originalModel {
            snTextField.text = model.snCode
            phoneTextField.text = model.phoneNo
            addressTextField.text = model.installAddress
        }
        
        scanButton.rx.tap.flatMapLatest {
            ScanQRViewController.rx.present()
        }
        .do(afterNext: {[weak self] (text) in
            self?.vm.snCode.accept(text)
        })
        .bind(to: snTextField.rx.text)
        .disposed(by: rx.disposeBag)
        
        snTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind(to: vm.snCode)
            .disposed(by: rx.disposeBag)
        
        phoneTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind(to: vm.phone)
            .disposed(by: rx.disposeBag)
        
        addressTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind(to: vm.address)
            .disposed(by: rx.disposeBag)
        
        bindLockButton.rx.bind(to: vm.saveAction, input: ())
        
        vm.saveAction.errors
            .subscribe(onNext: { (actionError) in
                PKHUD.sharedHUD.rx.showActionError(actionError)
            })
            .disposed(by: rx.disposeBag)
        
        vm.saveAction.elements
            .subscribe(onNext: { (success) in
                if success {
                    HUD.flash(.label("保存成功"), delay: 2)
                    NotificationCenter.default.post(name: .refreshState, object: NotificationRefreshType.configTask)
                    self.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: rx.disposeBag)
    }
}
