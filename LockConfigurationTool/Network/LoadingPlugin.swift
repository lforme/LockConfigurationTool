//
//  LoadingPlugin.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/20.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import Moya
import PKHUD

final class LoadingPlugin: PluginType {
    
    init() {}
    
    func willSend(_ request: RequestType, target: TargetType) {
        
        DispatchQueue.main.async {[weak self] in
            if !HUD.isVisible {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                guard let this = self else { return }
                HUD.show(.customView(view: this.creatAnimationView()))
            }
        }
    }
    
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            HUD.hide(afterDelay: 1)
        }
        
    }
    
    private func creatAnimationView() -> UIView {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let indicatorView = UIActivityIndicatorView(style: .gray)
        indicatorView.hidesWhenStopped = true
        indicatorView.startAnimating()
        indicatorView.center = view.center
        view.addSubview(indicatorView)
        view.backgroundColor = ColorClassification.hudColor.value
        return view
    }
}
