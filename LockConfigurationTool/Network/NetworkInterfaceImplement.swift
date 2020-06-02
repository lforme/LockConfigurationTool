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
        case .editUser:
            return .put
        case .user:
            return .get
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .editUser:
            return "/user"
        case .user:
            return "/user"
        case .hardwareLockList:
            return "/hardware_lock_config/page"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case let .editUser(parameter):
            return parameter.toJSON()
            
        case let .hardwareLockList(pageSize, pageIndex, startTime, endTime):
            return ["currentPage": pageIndex, "pageSize": pageSize, "startTime": startTime, "endTime": endTime]
            
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
