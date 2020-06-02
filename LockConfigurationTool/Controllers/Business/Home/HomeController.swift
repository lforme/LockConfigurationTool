//
//  HomeController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import Reusable
import ReactorKit
import RxCocoa
import RxSwift
import RxDataSources
import MJRefresh
import PKHUD
import SwiftDate

class HomeController: UIViewController, StoryboardView {
    
    var disposeBag: DisposeBag = DisposeBag()
    
    typealias Reactor = HomeViewReactor
    
    var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, ConfigureTaskListModel>>!
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "home_navi_filter_icon"), for: UIControl.State())
        button.contentHorizontalAlignment = .right
        button.frame.size = CGSize(width: 32, height: 32)
        return button
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "home_navi_add_icon"), for: UIControl.State())
        button.contentHorizontalAlignment = .right
        button.frame.size = CGSize(width: 32, height: 32)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "门锁配置"
        reactor = Reactor()
        setupUI()
        setupNavigationRightItems()
    }
    
    func setupNavigationRightItems() {
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: addButton), UIBarButtonItem(customView: filterButton)]
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 250
        tableView.register(cellType: HomeListCell.self)
        
    }
    
    func bind(reactor: HomeViewReactor) {
        
        addButton.rx.tap
            .map { Reactor.Action.addConfigTask }
            .bind(to: reactor.action)
            .disposed(by: rx.disposeBag)
        
        filterButton.rx.tap
            .flatMapLatest {
                DataPickerController.rx.present(with: "选择时间", items: [["一个月前", "二个月前", "三个月前", "四个月前", "五个月前", "半年前"]])
        }.flatMapLatest { (pickResult) -> Observable<Reactor.Action> in
            guard let subFactor = pickResult.first?.row else {
                let s = (Date() - 1.months).toFormat("yyyy-MM-dd HH:mm:ss")
                let e = Date().toFormat("yyyy-MM-dd HH:mm:ss")
                return .just(Reactor.Action.pickTime(s, e))
            }
            
            let s = (Date() - subFactor.months).toFormat("yyyy-MM-dd HH:mm:ss")
            let e = Date().toFormat("yyyy-MM-dd HH:mm:ss")
            
            return .just(Reactor.Action.pickTime(s, e))
        }
        .bind(to: reactor.action)
        .disposed(by: rx.disposeBag)
        
        
        let pullToRefreshAction = BehaviorRelay<Reactor.Action>(value: Reactor.Action.pullToRefresh)
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            pullToRefreshAction.accept(Reactor.Action.pullToRefresh)
        })
        
        pullToRefreshAction.asObservable()
            .delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: reactor.action)
            .disposed(by: self.rx.disposeBag)
        
        
        let pullUpLoadAction = BehaviorRelay<Reactor.Action>(value: Reactor.Action.pullUpLoading(1))
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: {
            pullUpLoadAction.accept(Reactor.Action.pullUpLoading(1))
        })
        footer.setTitle("", for: .idle)
        tableView.mj_footer = footer
        
        pullUpLoadAction.asObservable()
            .delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: reactor.action)
            .disposed(by: rx.disposeBag)
        
        reactor
            .state
            .map { $0.requestFinished }
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] (end) in
                if end {
                    self?.tableView.mj_header?.endRefreshing()
                    self?.tableView.mj_footer?.endRefreshing()
                }
            }).disposed(by: rx.disposeBag)
        
        reactor
            .state
            .map { $0.noMoreData }
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] (noMore) in
                if noMore {
                    self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
                }
            }).disposed(by: rx.disposeBag)
        
        dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ConfigureTaskListModel>>(configureCell: { (ds, tv, ip, item) -> HomeListCell in
            let cell: HomeListCell = tv.dequeueReusableCell(for: ip)
            
            return cell
        })
        
        reactor
            .state
            .map{ [SectionModel(model: "解锁记录", items: $0.dataList)] }
            .do(onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
            }).bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        reactor
            .state
            .map { $0.addResult }
            .subscribe(onNext: { (tap) in
                if tap != nil {
                    print("添加任务")
                }
            })
            .disposed(by: rx.disposeBag)
    }
}
