//
//  NetworkInterface.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import HandyJSON

enum AuthenticationInterface {
    // 获取短信验证码
    case verificationCode(phone: String)
    // 验证短信验证码并登录
    case registeriOS(phone: String, password: String, msmCode: String)
    // 验证短信验证码并修改密码
    case forgetPasswordiOS(phone: String, password: String, msmCode: String)
    // 用户面密码登录
    case login(userName: String, password: String)
    // 验证短信接口
    case verificationCodeValid(code: String, phone: String)
    // 刷新token
    case refreshToken(token: String)
    // 退出登录
    case logout(token: String)
}


enum BusinessInterface {
    // 获取当前用户信息
    case user
    // 修改用户密码
    case changePassword(oldPwd: String, newPwd: String)
    // 配置列表
    case hardwareLockList(pageSize: Int, pageIndex: Int, startTime: String?, endTime: String?)
    // 添加配置任务
    case hardwareLockConfigStorage(channels: String, snCode: String, phone: String, installAddress: String?)
    // 删除配置任务
    case deleteTask(id: String)
    // 编辑配置任务
    case hardwareLockConfigEdit(id: String, channels: String, snCode: String, phone: String, installAddress: String?)
    // 绑定门锁
    case bind(lock: LockModel)
    // 获取选择门锁列表
    case lockTypeList
}
