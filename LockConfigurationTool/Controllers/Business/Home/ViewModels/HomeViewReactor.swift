//
//  HomeViewReactor.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/2.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import ReactorKit
import RxSwift
import SwiftDate

final class HomeViewReactor: Reactor {
    
    enum Action {
        case addConfigTask
        case pickTime(String, String)
        case selectTask(String)
        case deleteTask(String)
        case configLock(String)
        case pullToRefresh
        case pullUpLoading(Int)
    }
    
    struct State {
        var pageIndex: Int
        var requestFinished: Bool
        var noMoreData: Bool
        var dataList: [ConfigureTaskListModel]
        var startTime: String
        var endTime: String
        var deleteResult: Bool?
        var addResult: Void?
    }
    
    enum Mutation {
        case setConfigTaskTap(Void)
        case setTime(String, String)
        case setPageIndex(Int)
        case setPageIndexToBegin
        case setRequestFinished(Bool)
        case setNoMoreData(Bool)
        case setDataList([ConfigureTaskListModel])
    }
    
    var initialState: State
    
    init() {
        let startTime = Date() - 1.months
        
        self.initialState = State(pageIndex: 1, requestFinished: true, noMoreData: false, dataList: [], startTime: startTime.toFormat("yyyy-MM-dd HH:mm:ss"), endTime: Date().toFormat("yyyy-MM-dd HH:mm:ss"), deleteResult: nil, addResult: nil)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        
        switch action {
        case .addConfigTask:
            return .just(.setConfigTaskTap(()))
            
        case let .pickTime(start, end):
            
            let share = self.request(pageIndex: self.currentState.pageIndex, start: start, end: end)
            let isNoMoreData = share.map { (list) -> Mutation in
                if list.count == 0 {
                    return .setNoMoreData(true)
                } else {
                    return .setNoMoreData(false)
                }
            }
            
            let isFinished = share.map { _ in Mutation.setRequestFinished(true) }
            
            let list = share.map { res in
                Mutation.setDataList(res)
            }
            
            return Observable.concat([.just(.setTime(start, end)),
                                      isNoMoreData,
                                      isFinished,
                                      list
            ])
            
        case .pullToRefresh:
            let share = self.request(pageIndex: self.currentState.pageIndex, start: self.currentState.startTime, end: self.currentState.endTime)
            
            let list = share.map { res in
                Mutation.setDataList(res)
            }
            let isFinished = share.map { _ in Mutation.setRequestFinished(true) }
            
            return Observable.concat([.just(.setPageIndexToBegin),
                                      .just(.setNoMoreData(false)),
                                      isFinished,
                                      list
            ])
            
        case let .pullUpLoading(pageIndex):
            let share = self.request(pageIndex: self.currentState.pageIndex + 1, start: self.currentState.startTime, end: self.currentState.endTime)
            
            if self.currentState.noMoreData {
                return .just(.setNoMoreData(true))
            }
            
            let list = share.map { res in
                Mutation.setDataList(res)
            }
            
            let isFinished = share.map { _ in Mutation.setRequestFinished(true) }
            
            return Observable.concat([.just(Mutation.setPageIndex(pageIndex)),
                                      isFinished,
                                      list])
            
        default:
            return .just(.setPageIndex(1))
        }
    }
    
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case let .setTime(s, e):
            state.startTime = s
            state.endTime = e
            
        case let .setPageIndex(index):
            state.pageIndex += index
            
        case .setPageIndexToBegin:
            state.pageIndex = 1
            
        case let .setRequestFinished(finished):
            state.requestFinished = finished
            
        case let .setNoMoreData(noMore):
            state.requestFinished = noMore
            
        case let .setDataList(list):
            state.dataList = list
            
        case let .setConfigTaskTap(tap):
            state.addResult = tap
        }
        
        return state
    }
}

extension HomeViewReactor {
    
    fileprivate func request(pageIndex: Int, start: String, end: String) -> Observable<[ConfigureTaskListModel]> {
        
        return BusinessAPI.requestMapJSONArray(.hardwareLockList(pageSize: 15, pageIndex: pageIndex, startTime: start, endTime: end), classType: ConfigureTaskListModel.self, useCache: true, isPaginating: true).map { $0.compactMap { $0 } }.share(replay: 1, scope: .forever)
    }
    
}
