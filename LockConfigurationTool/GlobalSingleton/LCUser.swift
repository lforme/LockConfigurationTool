//
//  LCUser.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class LCUser {
    
    // 私有
    private let lock = NSRecursiveLock()
    private static let instance = LCUser()
    private let changeableUserInfo = BehaviorRelay<UserModel?>(value: nil)
    private let changeableToken = BehaviorRelay<AccessTokenModel?>(value: nil)
    private let disposeBag = DisposeBag()
    private var diskStorage: NetworkDiskStorage?
    
    private init() {
        lock.name = "com.LSLUser.lock"
        changeableUserInfo.accept(self.user)
        changeableToken.accept(self.token)
    }
    
    // 公有
    var token: AccessTokenModel? {
        set {
            guard let entity = newValue?.toJSONString() else { return }
            lock.lock()
            LocalArchiver.save(key: LCUser.Keys.token.rawValue, value: entity)
            changeableToken.accept(newValue)
            lock.unlock()
        }
        
        get {
            let json = LocalArchiver.load(key: LCUser.Keys.token.rawValue) as? String
            let value = AccessTokenModel.deserialize(from: json)
            return value
        }
    }
    
    var user: UserModel? {
        set {
            guard let entity = newValue?.toJSONString() else { return }
            lock.lock()
            changeableUserInfo.accept(newValue)
            LocalArchiver.save(key: LCUser.Keys.userInfo.rawValue, value: entity)
            lock.unlock()
        }
        get {
            let json = LocalArchiver.load(key: LCUser.Keys.userInfo.rawValue) as? String
            let value = UserModel.deserialize(from: json)
            return value
        }
    }
    
    var observedIsLogin: Observable<Bool> {
        let hasUserInfo = changeableUserInfo.map { $0 != nil }
        let hasToken = changeableToken.map { $0 != nil }
        
        return Observable.combineLatest(hasToken, hasUserInfo).map { $0 && $1 }
    }
    
    var observedUser: Observable<UserModel?> {
        return changeableUserInfo.asObservable()
    }
    
    static func current() -> LCUser {
        return LCUser.instance
    }
    
    func logout() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if let t = token?.accessToken {
            AuthAPI.requestMapBool(.logout(token: t))
                .delaySubscription(.seconds(2), scheduler: MainScheduler.instance)
                .subscribe()
                .disposed(by: disposeBag)
        }
        
        if let userId = token?.userId {
            diskStorage = NetworkDiskStorage(autoCleanTrash: false, path: "network")
            let deleteDb = diskStorage?.deleteDataBy(id: userId) ?? false
            print("数据库网络缓存文件删除:\(deleteDb ? "成功" : "失败")")
        }
        
        Keys.allCases.forEach {
            print("已删除Key:\($0.rawValue)")
            LocalArchiver.remove(key: $0.rawValue)
        }
        
        changeableUserInfo.accept(nil)
        changeableUserInfo.accept(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {[weak self] in
            self?.diskStorage = nil
        }
    }
    
}


/// 归档的Key
extension LCUser {
    
    enum Keys: String, CaseIterable {
        case refreshToekn = "refreshToeknModel"
        case token = "tokenModel"
        case userInfo = "userInfoModel"
    }
}
