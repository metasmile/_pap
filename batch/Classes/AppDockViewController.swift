//
//  AppDockViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 4..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit

class AppDockViewController: UIViewController {
    @IBOutlet weak var appDockView: AppDockView!
    @IBOutlet weak var appDockViewBottomLayout: NSLayoutConstraint!
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
        doneButton = UIBarButtonItem(image: UIImage(named: "Batch Done Bar Button"), style: .done, target: self, action: #selector(self.doneButtonDidTap))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        appDockView.delegate = self
        appDockView.items = appDockItems
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController?.navigationBar.barStyle == UIBarStyle.black {
            cancelButton?.tintColor = .white
            doneButton?.tintColor = .white
        }
        else {
            cancelButton?.tintColor = .black
            doneButton?.tintColor = .black
        }
    }
    
    var appDockItems: [AppDockItem] {
        return BatchAppCenter.default.apps.map({ AppDockItem(app: $0) })
    }
    
    @objc func cancelButtonDidTap(sender: Any) {
        
    }
    
    @objc func horizontalFlipButtonDidTap() {
        
    }
    
    @objc func verticalFlipButtonDidTap() {
        
    }
    
    @objc func rotationLeftButtonDidTap() {
        
    }
    
    @objc func rotationRightButtonDidTap() {
        
    }
    
    @objc func doneButtonDidTap(sender: Any) {
        
    }
    
    lazy var transformAppConfigView: UIView = {
        let view = UIStackView(frame: .zero)
        view.alignment = .fill
        view.distribution = .fillEqually
        view.axis = .horizontal
        
        let config1 = UIButton(type: .system)
        config1.setImage(UIImage(named: "Flip Vertical")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config1.addTarget(self, action: #selector(self.verticalFlipButtonDidTap), for: .touchUpInside)
        
        let config2 = UIButton(type: .system)
        config2.setImage(UIImage(named: "Flip Horizontal")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config2.addTarget(self, action: #selector(self.horizontalFlipButtonDidTap), for: .touchUpInside)
        
        let config3 = UIButton(type: .system)
        config3.setImage(UIImage(named: "Rotate Left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config3.addTarget(self, action: #selector(self.rotationLeftButtonDidTap), for: .touchUpInside)
        
        let config4 = UIButton(type: .system)
        config4.setImage(UIImage(named: "Rotate Right")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config4.addTarget(self, action: #selector(self.rotationRightButtonDidTap), for: .touchUpInside)
        
        switch appDockView.barStyle {
        case .black:
            config1.tintColor = .white
            config2.tintColor = .white
            config3.tintColor = .white
            config4.tintColor = .white
        default:
            config1.tintColor = .black
            config2.tintColor = .black
            config3.tintColor = .black
            config4.tintColor = .black
        }
        
        view.addArrangedSubview(config1)
        view.addArrangedSubview(config2)
        view.addArrangedSubview(config3)
        view.addArrangedSubview(config4)
        
        return view
    }()
}
//TODO: TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP
extension AppDockViewController: AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        BatchAppCenter.default.current = item.app
        
        appDockView.setAppConfigView(generateAppConfigView(with: item.app))
    }
}

extension AppDockViewController {
    fileprivate func generateAppConfigView(with app: Appable.Type) -> UIView? {
        if app is TransformApp.Type {
            return transformAppConfigView
        }
        return nil
    }
}

extension AppDockViewController {
    open func showAppDock(_ animated: Bool = true) {
        appDockViewBottomLayout.constant = 0
        
        if animated {
            appDockView.animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    open func hideAppDock(_ animated: Bool = true) {
        appDockViewBottomLayout.constant = -(appDockView.bounds.height + safeAreaInsets.bottom)
        
        if animated {
            appDockView.animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
}

extension UIViewController {
    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        }
        else {
            return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
        }
    }
}
