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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        BatchAppCenter.default.current = BatchAppCenter.default.apps.first

        selectCurrentAppIfExist()
    }
    
    var appDockItems: [AppDockItem] {
        return BatchAppCenter.default.apps.map({ AppDockItem(app: $0) })
    }

    @objc func cancelButtonDidTap(sender: Any) {

    }

    @objc func doneButtonDidTap(sender: Any) {

    }
}

extension AppDockViewController {
    fileprivate func selectCurrentAppIfExist() {
        guard let indexOfCurrentApp = BatchAppCenter.default.currentIndex else { return }
        appDockView.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0))
    }
}

extension AppDockViewController: AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        BatchAppCenter.default.current = item.app

        updateAppDockViewForCurrentApp()
    }

    func updateAppDockViewForCurrentApp() {
        let configView = BatchAppCenter.default.currentInstanceAs(ConfigurableApp.self)?.configView
        appDockView.setAppConfigView(configView)
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
