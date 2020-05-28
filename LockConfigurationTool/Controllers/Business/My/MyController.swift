//
//  MyController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/5/28.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit

class MyController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "个人"
        setupUI()
    }

    func setupUI() {
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
    }
}
