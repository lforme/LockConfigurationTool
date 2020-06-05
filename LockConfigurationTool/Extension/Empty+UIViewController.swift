//
//  Empty+UIViewController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/29.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import UIKit
import DZNEmptyDataSet
import MJRefresh

extension UIViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    public func emptyDataSet(_ scrollView: UIScrollView!, didTap view: UIView!) {
        let tableView = self.view.subviews.filter { $0 is UITableView  }.first as? UITableView
        tableView?.mj_header?.beginRefreshing()
    }
    
    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "global_empty")
    }
    
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "O(∩_∩)O哈哈~什么都没有\n点击刷新"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): ColorClassification.textDescription.value,
                                                         NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        let attributeString = NSAttributedString(string: text, attributes: attributes)
        
        return attributeString
    }
    
    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        switch self {
        default:
            return -20
        }
    }
}
