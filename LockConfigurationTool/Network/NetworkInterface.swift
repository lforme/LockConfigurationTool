//
//  NetworkInterface.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation

enum AuthenticationInterface {
    
    case verificationCode(phone: String) // 获取短信验证码
    case registeriOS(phone: String, password: String, msmCode: String) // 验证短信验证码并登录
    case forgetPasswordiOS(phone: String, password: String, msmCode: String) // 验证短信验证码并修改密码
    case login(userName: String, password: String) // 用户面密码登录
    case verificationCodeValid(code: String, phone: String) // 验证短信接口
    case refreshToken(token: String) // 刷新token
    case logout(token: String) // 退出登录
}
