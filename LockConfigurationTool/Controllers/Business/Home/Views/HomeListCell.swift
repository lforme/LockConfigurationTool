//
//  HomeListCell.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/2.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import Reusable

class HomeListCell: UITableViewCell, Reusable {

    @IBOutlet weak var snNumber: UILabel!
    @IBOutlet weak var configStatus: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var configButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}
