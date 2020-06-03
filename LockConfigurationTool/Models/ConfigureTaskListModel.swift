//
//  ConfigureTaskListModel.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/2.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import HandyJSON

struct ConfigureTaskListModel: HandyJSON {
    
    enum LockConfigStatus: Int, HandyJSONEnum {
        case notConfigured = 1
        case configured = 2
    }
    
    var channels: String?
    var creatTime: String?
    var id: String?
    var installAddress: String?
    var installerName: String?
    var installerPhone: String?
    var isBinding: String?
    var isBindingNo: Bool?
    var isOnline: String?
    var isOnlineNo: LockConfigStatus?
    var passwordNo: String?
    var phoneNo: String?
    var snCode: String?
}

extension ConfigureTaskListModel: Hashable {
    
    static func < (lhs: ConfigureTaskListModel, rhs: ConfigureTaskListModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.channels)
        hasher.combine(self.creatTime)
        hasher.combine(self.id)
        hasher.combine(self.installAddress)
        hasher.combine(self.installerName)
        hasher.combine(self.installerPhone)
        hasher.combine(self.isBinding)
        hasher.combine(self.isBindingNo)
        hasher.combine(self.isOnline)
        hasher.combine(self.isOnlineNo)
        hasher.combine(self.passwordNo)
        hasher.combine(self.phoneNo)
        hasher.combine(self.snCode)
    }
    
}
