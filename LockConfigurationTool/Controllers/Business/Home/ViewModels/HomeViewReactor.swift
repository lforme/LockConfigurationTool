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
import PKHUD
import SwiftDate

final class HomeViewReactor: Reactor {
    
    enum Action {
        case pickTime(String?, String?)
        case pullToRefresh(Int?)
        case pullUpLoading(Int?)
    }
    
    struct State {
        var pageIndex: Int
        var requestFinished: Bool
        var noMoreData: Bool
        var dataList: [ConfigureTaskListModel]
        var startTime: String?
        var endTime: String?
    }
    
    enum Mutation {
        case setTime(String?, String?)
        case setPullUpLoading(Int)
        case setPullToRefresh(Int)
        case setRequestFinished(Bool)
        case setNoMoreData(Bool)
        case setRefreshList([ConfigureTaskListModel])
        case setLoadList([ConfigureTaskListModel])
    }
    
    var initialState: State
    
    init() {
        
        self.initialState = State(pageIndex: 0, requestFinished: true, noMoreData: false, dataList: [], startTime: nil, endTime: nil)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        
        switch action {
            
        case let .pickTime(start, end):
            
            let share = self.request(pageIndex: self.currentState.pageIndex, start: start, end: end)
            
            let list = share.map { res in
                Mutation.setRefreshList(res)
            }
            return Observable.concat([
                .just(.setTime(start, end)),
                list
            ])
            
        case let .pullToRefresh(pageIndex):
            
            guard let index = pageIndex else {
                return .empty()
            }
            
            let share = self.request(pageIndex: index, start: self.currentState.startTime, end: self.currentState.endTime)
            
            let pageMutation = Observable.just(Mutation.setPullToRefresh(index))
            
            let list = share.map {
                Mutation.setRefreshList($0)
            }
            
            let isFinished = share.map { _ in
                Mutation.setRequestFinished(true)
            }
            
            return Observable.concat([
                pageMutation,
                isFinished,
                list
            ])
            
        case let .pullUpLoading(pageIndex):
            guard let index = pageIndex else {
                return .empty()
            }
            
            let share = self.request(pageIndex: self.currentState.pageIndex, start: self.currentState.startTime, end: self.currentState.endTime)
                .distinctUntilChanged()
            
            let pageMutation = Observable.just(Mutation.setPullUpLoading(index))
            
            let list = share.map {
                Mutation.setLoadList($0)
            }
            
            let isFinished = share.map { _ in Mutation.setRequestFinished(true) }
            
            let noMore = share.map  {
                Mutation.setNoMoreData($0.count == 0)
            }
            
            return Observable.concat([
                pageMutation,
                isFinished,
                noMore,
                list
            ])
        }
    }
    
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case let .setTime(s, e):
            state.startTime = s
            state.endTime = e
            
        case let .setPullUpLoading(page):
            state.pageIndex += page
            
        case let .setPullToRefresh(page):
            state.pageIndex = page
            
        case let .setRequestFinished(finished):
            state.requestFinished = finished
            
        case let .setNoMoreData(noMore):
            state.noMoreData = noMore
            
        case let .setRefreshList(list):
            state.dataList = list
            
        case let .setLoadList(list):
            state.dataList += list
            let sort = Set(state.dataList).sorted { (a, b) -> Bool in
                let aa = a.creatTime?.toInt() ?? 0
                let bb = b.creatTime?.toInt() ?? -1
                return aa > bb
            }
            state.dataList = sort
        }
        return state
    }
}

extension HomeViewReactor {
    
    func deleteTask(id: Observable<String?>) -> Observable<Bool> {
        return id.flatMapLatest { (o) -> Observable<Bool> in
            guard let o = o else {
                return .empty()
            }
            return BusinessAPI.requestMapBool(.deleteTask(id: o))
        }
    }
    
    fileprivate func request(pageIndex: Int, start: String?, end: String?) -> Observable<[ConfigureTaskListModel]> {
        
        return BusinessAPI.requestMapJSONArray(.hardwareLockList(pageSize: 15, pageIndex: pageIndex, startTime: start, endTime: end), classType: ConfigureTaskListModel.self, useCache: true, isPaginating: true)
            .map { $0.compactMap { $0 } }
            .share(replay: 1, scope: .forever)
            .do(onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
            })
    }
    
}
