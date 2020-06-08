//
//  SelectLockTypeController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/12/4.
//  Copyright © 2019 mugua. All rights reserved.
//

import UIKit
import PKHUD

class SelectLockTypeCell: UITableViewCell {
    
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var lockName: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}

class SelectLockTypeController: UITableViewController, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.navigationBackground.value
    }
    
    var configModel: ConfigureTaskListModel!
    var dataSource = [LockTypeModel]()
    
    deinit {
        print("\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        title = "选择门锁类型"
        setupUI()
        bind()
    }
    
    func bind() {
        BusinessAPI.requestMapJSONArray(.lockTypeList(channels: "00"), classType: LockTypeModel.self, useCache: true, isPaginating: true)
            .map { $0.compactMap { $0 } }
            .subscribe(onNext: {[weak self] (items) in
                self?.dataSource = items
                self?.tableView.reloadData()
                }, onError: { (error) in
                    PKHUD.sharedHUD.rx.showError(error)
            }).disposed(by: rx.disposeBag)
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 112
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectLockTypeCell", for: indexPath) as! SelectLockTypeCell
        cell.lockImage.setUrl(dataSource[indexPath.row].tyeUrl)
        cell.lockName.text = dataSource[indexPath.row].typeName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        BluetoothPapa.shareInstance.removeAESkey()
        
        let initialLockVC: LockStartScanningController = ViewLoader.Storyboard.controller(from: "InitialLock")
        let lock = LockModel()
        lock.lockType = dataSource[indexPath.row].typeName
        lock.deviceType = dataSource[indexPath.row].typeName
        lock.configId = configModel.id
        lock.serialNumber = configModel.snCode
        initialLockVC.lockInfo = lock
        navigationController?.pushViewController(initialLockVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ColorClassification.tableViewBackground.value
    }
}
