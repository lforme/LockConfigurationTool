//
//  NetworkInterfaceImplement.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import UIKit
import HandyJSON
import Moya

extension AuthenticationInterface: TargetType {
    
    var baseURL: URL {
        return URL(string: ServerHost.shared.environment.host)!
    }
    
    var headers: [String : String]? {
        switch self {
        default:
            return ["Content-Type": "application/json"]
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .verificationCode: return .get
        case .logout: return .delete
        default:
            return .post
        }
    }
    
    var path: String {
        
        switch self {
        case .login:
            return "/login/login"
        case .verificationCodeValid:
            return "/common/verification_code/valid"
        case let .verificationCode(phone):
            return "/common/verification_code/\(phone)"
        case .registeriOS:
            return "/login/register/ios"
        case .forgetPasswordiOS:
            return "/login/forget_password/ios"
        case let .refreshToken(token):
            return "/login/refresh_token/\(token)"
        case let .logout(token):
            return "/login/logout/\(token)"
        }
    }
    
    var parameters: [String: Any]? {
        
        switch self {
        case let .login(phone, password):
            return [
                "phone": phone,
                "password": password
            ]
        case let .registeriOS(phone, password, msmCode):
            return ["password": password, "phone": phone, "verificationCode": msmCode, "userType": 1]
            
        case let .forgetPasswordiOS(phone, password, msmCode):
            return ["password": password, "phone": phone, "verificationCode": msmCode]
            
        case let .verificationCodeValid(code, phone):
            return ["phone": phone, "verificationCode": code]
        default: return nil
        }
    }
    
    var task: Task {
        let requestParameters = parameters ?? [:]
        let encoding: ParameterEncoding
        switch self.method {
        case .post:
            if self.path == "token" {
                encoding = URLEncoding.default
            } else {
                encoding = JSONEncoding.default
            }
        default:
            encoding = URLEncoding.default
        }
        return .requestParameters(parameters: requestParameters, encoding: encoding)
    }
    
    var sampleData: Data {
        switch self {
        default:
            return Data(base64Encoded: "业务测试数据") ?? Data()
        }
    }
}



extension BusinessInterface: TargetType {
    
    var sampleData: Data {
        switch self {
        default:
            return Data()
        }
    }
    
    var baseURL: URL {
        return URL(string: ServerHost.shared.environment.host)!
    }
    
    var headers: [String : String]? {
        guard let entiy = LCUser.current().token else { return nil }
        
        guard let token = entiy.accessToken, let type = entiy.tokenType else {
            return nil
        }
        return ["Authorization": type + token]
    }
    
    var method: Moya.Method {
        switch self {
        case .user,
             .lockTypeList:
            return .get
        case .hardwareLockConfigEdit:
            return .put
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .changePassword:
            return "/user/password"
        case .user:
            return "/user"
        case .hardwareLockList:
            return "/hardware_lock_config/page"
        case .hardwareLockConfigStorage:
             return "/hardware_lock_config/storage"
        case let .deleteTask(id):
            return "/hardware_lock_config/delete/\(id)"
        case let .hardwareLockConfigEdit(id, _, _, _, _):
            return "/hardware_lock_config/update/\(id)"
        case .bind:
            return "/hardware_lock/configuration"
        case .lockTypeList:
            return "/hardware_lock_config/lockType"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case let .changePassword(oldPwd, newPwd):
            return ["oldPassword": oldPwd, "password": newPwd]
            
        case let .hardwareLockList(pageSize, pageIndex, startTime, endTime):
            var dict: [String: Any] = ["currentPage": pageIndex, "pageSize": pageSize]
            
            if let s = startTime {
                
                dict.updateValue(s, forKey: "startTime")
            }
            if let e = endTime {
                dict.updateValue(e, forKey: "endTime")
            }
            return dict
            
        case let .hardwareLockConfigStorage(channels, snCode, phone, installAddress):
            var dict = ["channels": channels, "phoneNo": phone, "snCode": snCode]
            if let address = installAddress {
                dict.updateValue(address, forKey: "installAddress")
            }
            return dict
           
        case let .hardwareLockConfigEdit(_, channels, snCode, phone, installAddress):
            
            var dict = ["channels": channels, "phoneNo": phone, "snCode": snCode]
            if let address = installAddress {
                dict.updateValue(address, forKey: "installAddress")
            }
            return dict
            
        case let .bind(lock):
            return lock.toJSON()
    
        default:
            return nil
        }
    }
    
    var task: Task {
        let requestParameters = parameters ?? [:]
        var encoding: ParameterEncoding = JSONEncoding.default
        
        if self.method == .get {
            encoding = URLEncoding.default
            return .requestParameters(parameters: requestParameters, encoding: encoding)
        }
        return .requestParameters(parameters: requestParameters, encoding: encoding)
    }
}
