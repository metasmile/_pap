//
//  AppDockViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 4..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit

class AppDockViewController: UIViewController {
    @IBOutlet weak var appDockView: STAppDockView!
    @IBOutlet weak var appDockViewBottomLayout: NSLayoutConstraint!
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
        doneButton = UIBarButtonItem(image: UIImage(named: "Batch Done Bar Button"), style: .done, target: self, action: #selector(self.doneButtonDidTap))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
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
        return [
            AppDockItem(title: "Flip Vertical", appIcon: UIImage(named: "Flip Vertical"), run: { self.verticalFlipButtonDidTap() }),
            AppDockItem(title: "Flip Horizontal", appIcon: UIImage(named: "Flip Horizontal"), run: { self.horizontalFlipButtonDidTap() }),
            AppDockItem(title: "Rotate Left", appIcon: UIImage(named: "Rotate Left"), run: { self.rotationLeftButtonDidTap() }),
            AppDockItem(title: "Rotate Right", appIcon: UIImage(named: "Rotate Right"), run: { self.rotationRightButtonDidTap() })
        ]
    }
    
    @objc func cancelButtonDidTap(sender: Any) {
        
    }
    
    func horizontalFlipButtonDidTap() {
        
    }
    
    func verticalFlipButtonDidTap() {
        
    }
    
    func rotationLeftButtonDidTap() {
        
    }
    
    func rotationRightButtonDidTap() {
        
    }
    
    @objc func doneButtonDidTap(sender: Any) {
        
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
