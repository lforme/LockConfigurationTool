//
//  TaskDetailViewModel.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/3.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import PKHUD
import Action

final class TaskDetailViewModel {
    
    let snCode = BehaviorRelay<String?>(value: nil)
    let phone = BehaviorRelay<String?>(value: nil)
    let address = BehaviorRelay<String?>(value: nil)
    
    var saveAction: Action<(), Bool>!
    
    let type: TaskDetailController.EditType
    private let model: ConfigureTaskListModel?
    
    init(type: TaskDetailController.EditType, model: ConfigureTaskListModel?) {
        self.model = model
        self.type = type
        
        let enable = Observable.combineLatest(snCode, phone).map { $0.0.isNotNilNotEmpty && $0.1.isNotNilNotEmpty && $0.1?.count == 11 }
        
        self.saveAction = Action.init(enabledIf: enable, workFactory: {[unowned self] (_) -> Observable<Bool> in
            if self.snCode.value!.count < 4 {
                return .error(AppError.reason("发生未知错误, 二维码位数少用4位"))
            }
            
            switch self.type {
            case .addNew:
                return BusinessAPI.requestMapBool(.hardwareLockConfigStorage(channels: self.snCode.value![2..<4], snCode: self.snCode.value!, phone: self.phone.value!, installAddress: self.address.value))
                
            case .modify:
                guard let id = model?.id else {
                    return .error(AppError.reason("发生未知错误, 无法获取Id."))
                }
                
                return BusinessAPI.requestMapBool(.hardwareLockConfigEdit(id: id, channels: self.snCode.value![2..<4], snCode: self.snCode.value!, phone: self.phone.value!, installAddress: self.address.value))
            }
        })
    }
}
