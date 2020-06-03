//
//  LockModels.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import HandyJSON


struct UnlockRecordModel: HandyJSON {
    
    var openTime: String?
    var openType: String?
    var userName: String?
}

class LockModel: HandyJSON {
    
    required init() {}
    
    var bluetoothName: String?
    var bluetoothPwd: String?
    var bluetoothVersion: String?
    var configId: String?
    var deviceType: String?
    var fingerVersion: String?
    var firmwareVersion: String?
    var imei: String?
    var imsi: String?
    var ipAddress: String?
    var lockCode: String?
    var lockType: String?
    var nbVersion: String?
    var passwordNo: String?
    var serialNumber: String?
    var voice: String = "2"
}
