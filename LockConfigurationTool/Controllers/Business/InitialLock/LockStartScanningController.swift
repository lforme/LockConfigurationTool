//
//  LockStartScanningController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/12/4.
//  Copyright © 2019 mugua. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class LockStartScanningController: UIViewController, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.navigationBackground.value
    }
    
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var stepOneView: UIView!
    @IBOutlet weak var stepTwoView: UIView!
    
    let vm = LockStartScanViewModel()
    var bindVM: LockBindViewModel!
    var lockInfo: LockModel!
    
    fileprivate var privateKey: String {
        func randomString(length: Int) -> String {
            let letters = "0123456789"
            return String((0..<length).map{ _ in letters.randomElement()! })
        }
        return randomString(length: 16)
    }
    
    deinit {
        HUD.hide()
        print("\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "添加门锁"
        setupUI()
        bind()
    }
    
    func bind() {
        BluetoothPapa.shareInstance.scanForPeripherals(true)
        
        bindVM = LockBindViewModel.init(lockInfo: self.lockInfo)
        vm.setupAction()
        scanButton.rx.bind(to: vm.scanAction, input: ())
        
        vm.scanAction.errors.subscribe(onNext: { (error) in
            PKHUD.sharedHUD.rx.showActionError(error)
        }).disposed(by: rx.disposeBag)
        
        vm.scanAction.elements.flatMapLatest {[unowned self] (isConnected) -> Observable<LockBindViewModel.Step> in
            if isConnected {
                return self.bindVM.shakeHand()
            } else {
                return .just(.scaning)
            }
        }.flatMapLatest {[unowned self] (s) -> Observable<LockBindViewModel.Step> in
            HUD.show(.label(s.description))
            return self.bindVM.setPrivateKey(self.privateKey)
        }.flatMapLatest {[unowned self] (s) -> Observable<LockBindViewModel.Step> in
            HUD.show(.label(s.description))
            return self.bindVM.setAdiminPassword(self.generateRandomPassword())
        }.flatMapLatest {[unowned self] (s) -> Observable<LockBindViewModel.Step> in
            HUD.show(.label(s.description))
            return self.bindVM.checkVersionInfo()
        }.flatMapLatest({[unowned self] (s) -> Observable<LockBindViewModel.Step> in
            HUD.show(.label(s.description))
            return self.bindVM.changeBroadcastName()
        }).flatMapLatest {[unowned self] (s) -> Observable<LockBindViewModel.Step> in
            HUD.show(.label(s.description))
            return self.bindVM.uploadToServer()
        }.subscribe(onNext: {[weak self] (step) in
            self?.stepLabel.text = step.description
            switch step {
            case let .uploadInfoToServer(success):
                if success {
                    HUD.flash(.label("绑定成功"), delay: 2)
                    NotificationCenter.default.post(name: .refreshState, object: NotificationRefreshType.configTask)
                    self?.navigationController?.popToRootViewController(animated: true)
                } else {
                    HUD.flash(.label("绑定失败"), delay: 2)
                    BluetoothPapa.shareInstance.factoryReset { (_) in
                        
                    }
                }
            case .scaning:
                self?.stepOneView.backgroundColor = ColorClassification.primary.value
                self?.stepTwoView.backgroundColor = .white
            default:
                self?.stepOneView.backgroundColor = ColorClassification.primary.value
                self?.stepTwoView.backgroundColor = .white
            }
            
            }, onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
                BluetoothPapa.shareInstance.factoryReset { (_) in
                    
                }
        }).disposed(by: rx.disposeBag)
        
        vm.scanAction.executing.subscribe(onNext: { (executing) in
            if executing {
                HUD.show(.label("正在扫描..."))
            }
        }).disposed(by: rx.disposeBag)
        
    }
    
    func setupUI() {
        scanButton.setCircular(radius: scanButton.bounds.height / 2)
        desLabel.text = "注意事项:\n1.打开门锁内面版长按[功能键], 待门锁发出[请打开手机蓝牙和APP]后松手.\n2.请务必站在门锁前方打开手机蓝牙进行绑定."
    }
    
    func generateRandomPassword() -> String {
        let array = Array(0...9)
        let random = array.shuffled()[0..<6].map { String($0) }
        let pwd = random.joined()
        return pwd
    }
}
