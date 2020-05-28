//
//  LoginViewReactor.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/21.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import ReactorKit
import RxSwift
import HandyJSON

final class LoginViewReactor: Reactor {
    
    let validationService = LoginValidationService()
    
    enum Action {
        case phonePasswordChanged(String, String)
        case showPassword(Bool)
        case login
    }
    
    struct State {
        var phone: String
        var password: String
        var validationResult: LoginValidationResult
        var showPassword: Bool
        var loginError: AppError?
        var userInfo: UserModel?
    }
    
    enum Mutation {
        case setPhonePassword(String, String)
        case setValidationResult(LoginValidationResult)
        case setLoginResult(AppError?, UserModel?)
        case setShowPassword(Bool)
    }
    
    let initialState: State
    
    init() {
        self.initialState = State(phone: "", password: "", validationResult: .empty, showPassword: false, loginError: nil, userInfo: nil)
    }
    
    
    func mutate(action: Action) -> Observable<Mutation> {
        
        switch action {
        case let .phonePasswordChanged(phone, pwd):
            return Observable.concat([
                Observable.just(.setPhonePassword(phone, pwd)),
                validationService.validatePhone(phone, password: pwd).map(Mutation.setValidationResult)
            ])
            
        case let .showPassword(show):
            return .just(.setShowPassword(show))
            
        case .login:
            
            let getUser = AuthAPI.requestMapJSON(.login(userName: self.currentState.phone, password: self.currentState.password), classType: AccessTokenModel.self).flatMapLatest { token -> Observable<UserModel> in
                
                LCUser.current().token = token
                return .just(UserModel())
            }
            
            return Observable.concat([
                Observable.just(Mutation.setLoginResult(nil, nil)),
                getUser.map({ (user) -> Mutation in
                    if user.id == nil {
                        return Mutation.setLoginResult( AppError.reason("无法获取用户信息"), nil)
                    }
                    
        
                    return Mutation.setLoginResult(nil, user)
                }).catchError({ (error) -> Observable<Mutation> in
                    if let e = error as? AppError {
                        return .just(.setLoginResult(e, nil))
                    } else {
                        return .just(.setLoginResult( AppError.reason(error.localizedDescription), nil))
                    }
                })
            ])
        }
    }
    
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case let .setPhonePassword(phone, pwd):
            state.phone = phone
            state.password = pwd
            state.loginError = nil
            state.userInfo = nil
        case let .setLoginResult(error, user):
            state.loginError = error
            state.userInfo = user
            
        case let .setShowPassword(show):
            state.showPassword = show
            
        case let .setValidationResult(validate):
            state.validationResult = validate
            
        }
        return state
    }
}
