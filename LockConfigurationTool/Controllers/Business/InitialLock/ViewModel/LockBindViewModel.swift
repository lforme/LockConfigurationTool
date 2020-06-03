//
//  LockBindViewModel.swift
//  LightSmartLock
//
//  Created by mugua on 2019/12/4.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class LockBindViewModel {
    
    private var lockInfo: LockModel
    
    init(lockInfo: LockModel) {
        self.lockInfo = lockInfo
    }
    
    func setPrivateKey(_ key: String) -> Observable<Step> {
        return Observable<Step>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.set(key: key) {[weak self] (data) in
                guard let tuple = BluetoothPapa.serializeKey(data) else {
                    observer.onError(AppError.reason("设置通信私钥失败\n请重新尝试"))
                    return
                }
                
                self?.lockInfo.imei = tuple.IMEI
                self?.lockInfo.imsi = tuple.IMSI
                self?.lockInfo.bluetoothPwd = key
                
                observer.onNext(.setPrivateKey)
                observer.onCompleted()
            }
            return Disposables.create()
        }.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
    
    func setAdiminPassword(_ password: String) -> Observable<Step> {
        return Observable<Step>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.setAdministrator(password: password) {[weak self] (data) in
                let success = BluetoothPapa.serializeAdminPassword(data)
                if success {
                    observer.onNext(.setAdiminPassword)
                    observer.onCompleted()
                    self?.lockInfo.passwordNo = password
                } else {
                    observer.onError(AppError.reason("设置管理员密码失败\n请重新尝试"))
                }
            }
            return Disposables.create()
        }.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
    
    func checkVersionInfo() -> Observable<Step> {
        return Observable<Step>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.checkVersions {[weak self] (data) in
                let result = BluetoothPapa.serializeVersions(data)
                guard let nb = result?["BN版本"] as? String, let fv = result?["指纹版本"] as? String, let lv = result?["门锁版本"] as? String, let bv = result?["蓝牙版本"] as? String else {
                    return observer.onError(AppError.reason("获取门锁信息失败\n请重新尝试"))
                }
                
                self?.lockInfo.nbVersion = nb
                self?.lockInfo.fingerVersion = fv
                self?.lockInfo.firmwareVersion = lv
                self?.lockInfo.bluetoothVersion = bv
                
                observer.onNext(.checkVersionInfo)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
    
    func changeBroadcastName() -> Observable<Step> {
        return Observable<Step>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.changeBroadcastName {[weak self] (data) in
                let result = BluetoothPapa.serializeChangeBroadcastName(data)
                guard let a = result?.Time, let b = result?.IMEIsuffix else {
                    return observer.onError(AppError.reason("改变广播名称失败\n请重新尝试"))
                }
                self?.lockInfo.bluetoothName = a + b
                observer.onNext(.changeBroadcastName)
                observer.onCompleted()
            }
            return Disposables.create()
        }.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
    
    func shakeHand() -> Observable<Step> {
        return Observable<Step>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.scanForPeripherals(false)
            BluetoothPapa.shareInstance.handshake {[weak self] (data) in
                let tuple = BluetoothPapa.serializeShake(data)
                
                if tuple?.Mac.isEmpty ?? false {
                    return observer.onError(AppError.reason("握手失败\n请重新尝试"))
                }
                
                self?.lockInfo.bluetoothName = tuple?.Mac
                self?.lockInfo.ipAddress = tuple?.Mac
                self?.lockInfo.lockCode = tuple?.Mac
                observer.onNext(.changeBroadcastName)
                observer.onCompleted()
            }
            return Disposables.create()
        }.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
    
    func uploadToServer() -> Observable<Step> {
        return BusinessAPI.requestMapBool(.bind(lock: self.lockInfo)).map {
            Step.uploadInfoToServer(success: $0)
        }
    }
}

extension LockBindViewModel {
    
    enum Step: CustomStringConvertible {
        case scaning
        case shakeHand
        case setAdiminPassword
        case checkVersionInfo
        case changeBroadcastName
        case setPrivateKey
        case uploadInfoToServer(success: Bool)
        
        var description: String {
            switch self {
            case .scaning:
                return "正在扫描连接中..."
            case .shakeHand:
                return "正在连接握手..."
            case .setAdiminPassword:
                return "设置管理员密码..."
            case .checkVersionInfo:
                return "查询版本信息..."
            case .changeBroadcastName:
                return "修改蓝牙广播名称..."
            case .setPrivateKey:
                return "设置通信私钥..."
            case .uploadInfoToServer:
                return "上传门锁信息..."
            }
        }
    }
}
