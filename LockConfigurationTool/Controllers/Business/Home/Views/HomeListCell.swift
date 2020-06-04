//
//  HomeListCell.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/2.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import Reusable
import RxCocoa
import RxSwift
class HomeListCell: UITableViewCell, NibReusable {

    @IBOutlet weak var snNumber: UILabel!
    @IBOutlet weak var configStatus: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var configButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var editButton: UIButton!
    
    private(set) var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.setCircularShadow(radius: 7, color: ColorClassification.textPlaceholder.value)
    }

}
