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
    
    var channels: String?
    var creatTime: String?
    var id: String?
    var installAddress: String?
    var installerName: String?
    var installerPhone: String?
    var isBinding: String?
    var isBindingNo: Bool?
    var isOnline: String?
    var isOnlineNo: Bool?
    var passwordNo: String?
    var phoneNo: String?
    var snCode: String?
}
