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

class HomeController: UIViewController, StoryboardView, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.tableViewBackground.value
    }
    
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
        setupObserver()
    }
    
    func setupObserver() {
        NotificationCenter.default.rx.notification(.refreshState)
            .takeUntil(rx.deallocated)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (notiObj) in
                guard let type = notiObj.object as? NotificationRefreshType else { return }
                if type == .configTask {
                    self?.tableView.mj_header?.beginRefreshing()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
                        self?.tableView.reloadEmptyDataSet()
                    }
                }
            }).disposed(by: rx.disposeBag)
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
        tableView.mj_header?.beginRefreshing()
    }
    
    func bind(reactor: HomeViewReactor) {
        
        addButton.rx.tap
            .subscribe(onNext: {[weak self] (_) in
                let taskDetailVC: TaskDetailController = ViewLoader.Storyboard.controller(from: "Home")
                taskDetailVC.type = .addNew
                self?.navigationController?.pushViewController(taskDetailVC, animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        filterButton.rx.tap
            .flatMapLatest {
                DataPickerController.rx.present(with: "选择时间", items: [["一个月前", "二个月前", "三个月前", "四个月前", "五个月前", "半年前", "全部"]])
        }.flatMapLatest { (pickResult) -> Observable<Reactor.Action> in
            guard let subFactor = pickResult.first?.row else {
                return .empty()
            }
            
            if subFactor == 6 {
                return .just(Reactor.Action.pickTime(nil, nil))
            }
            
            let s = (Date() - (subFactor + 1).months).toFormat("yyyy-MM-dd HH:mm:ss")
            let e = Date().toFormat("yyyy-MM-dd HH:mm:ss")
            
            return .just(Reactor.Action.pickTime(s, e))
        }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        
        let pullToRefreshAction = BehaviorRelay<Reactor.Action>(value: Reactor.Action.pullToRefresh(nil))
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            pullToRefreshAction.accept(Reactor.Action.pullToRefresh(0))
        })
        
        pullToRefreshAction.asObservable()
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        let pullUpLoadAction = BehaviorRelay<Reactor.Action>(value: Reactor.Action.pullUpLoading(nil))
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: {
            pullUpLoadAction.accept(Reactor.Action.pullUpLoading(1))
        })
        footer.setTitle("", for: .idle)
        tableView.mj_footer = footer
        
        pullUpLoadAction.asObservable()
            .delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        Observable
            .zip(tableView.rx.modelSelected(ConfigureTaskListModel.self), tableView.rx.itemSelected)
            .subscribe(onNext: {[weak self] (arg) in
                self?.tableView.deselectRow(at: arg.1, animated: true)
                let detailVC: TaskDetailController = ViewLoader.Storyboard.controller(from: "Home")
                detailVC.type = .modify
                detailVC.originalModel = arg.0
                self?.navigationController?.pushViewController(detailVC, animated: true)
            }).disposed(by: rx.disposeBag)
        
        reactor
            .state
            .map { $0.requestFinished }
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] (end) in
                if end {
                    self?.tableView.mj_header?.endRefreshing()
                    self?.tableView.mj_footer?.endRefreshing()
                }
            }).disposed(by: disposeBag)
        
        reactor
            .state
            .map { $0.noMoreData }
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] (noMore) in
                if noMore {
                    self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
                }
            }).disposed(by: disposeBag)
        
        dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ConfigureTaskListModel>>(configureCell: { (ds, tv, ip, item) -> HomeListCell in
            
            let cell = tv.dequeueReusableCell(for: ip, cellType: HomeListCell.self)
            cell.snNumber.text = item.snCode
            cell.phone.text = item.phoneNo
            cell.address.text = item.installAddress
            cell.date.text = item.creatTime
            cell.configStatus.text = item.isOnline
            if item.isOnlineNo == .some(.notConfigured) {
                cell.statusIcon.isHidden = false
                cell.configButton.isHidden = false
                cell.deleteButton.isHidden = false
            } else {
                cell.statusIcon.isHidden = true
                cell.configButton.isHidden = true
                cell.deleteButton.isHidden = true
            }
            
            let deleteTap = cell.deleteButton.rx.tap
                .flatMapLatest {[weak self] (_) -> Observable<String?> in
                    guard let this = self else {
                        return .empty()
                    }
                    return this.showAlert(title: "删除任务", message: "确定要删除未配置的任务吗", buttonTitles: ["删除", "取消"], highlightedButtonIndex: 1).map {
                        if $0 == 0 {
                            return item.id
                        } else {
                            return nil
                        }
                    }
            }
            
            reactor.deleteTask(id: deleteTap)
                .subscribe(onNext: { (isDelete) in
                    if isDelete {
                        HUD.flash(.label("删除成功"), delay: 2)
                        NotificationCenter.default.post(name: .refreshState, object: NotificationRefreshType.configTask)
                    }
                }, onError: { (error) in
                    PKHUD.sharedHUD.rx.showError(error)
                })
                .disposed(by: cell.disposeBag)
            
            cell.configButton.rx
                .tap
                .subscribe(onNext: {[weak self] (_) in
                    
                    let bindLockVC: SelectLockTypeController = ViewLoader.Storyboard.controller(from: "InitialLock")
                    bindLockVC.configModel = item
                    self?.navigationController?.pushViewController(bindLockVC, animated: true)
                }).disposed(by: cell.disposeBag)
            
            cell.phoneButton.rx
                .tap
                .subscribe(onNext: { (_) in
                    guard let phone = item.phoneNo else {
                        return
                    }
                    if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                    
                }).disposed(by: cell.disposeBag)
            
            return cell
        })
        
        reactor
            .state
            .map{ [SectionModel(model: "配置列表", items: $0.dataList)] }
            .do(onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
            }).bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
