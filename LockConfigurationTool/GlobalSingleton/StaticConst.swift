//
//  StaticConst.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import UIKit

let kLSRem = UIScreen.main.bounds.width / 375

enum NotificationRefreshType {
    case configTask
    
}

extension NSNotification.Name {
    
    static let statuBarDidChange = NSNotification.Name(rawValue: "statuBarDidChange")
    static let refreshState = NSNotification.Name(rawValue: "refreshState")
}


struct PlatformKey {
    static let none = ""
}


