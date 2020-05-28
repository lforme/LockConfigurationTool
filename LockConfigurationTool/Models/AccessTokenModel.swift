//
//  AccessTokenModel.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import HandyJSON

struct AccessTokenModel: HandyJSON {
        
    var accessToken: String?
    var license: String?
    var tokenType: String?
    var userId: String?
}
