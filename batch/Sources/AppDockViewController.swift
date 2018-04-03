//
//  AppDockViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 4..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit

class AppDockNavigationController: UINavigationController {
    lazy var appDockView: AppDockView = {
        let view = AppDockView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: 60)))
        view.delegate = self
        return view
    }()
    
    lazy var dimmedView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = .black
        view.alpha = 0.5
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    func initialize() {
        view.addSubview(dimmedView)
        dimmedView.fitConstraints(to: view)
        
        view.addSubview(appDockView)
        
        appDockView.translatesAutoresizingMaskIntoConstraints = false
        appDockView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        appDockView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        appDockView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewControllers.forEach({ $0.viewDidLayoutSubviews() })
    }
}

extension AppDockNavigationController: AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        AppCenter.default.current = item.app
        
        let configView = AppCenter.default.currentInstanceAs(UIControllableApp.self)?.controlView
        appDockView.setAppConfigView(configView)
        
        appDockView.closeDrawer(reloadDockAccessoryView: true)
    }
    
    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        UIView.transition(with: dimmedView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = !isOpened
        }, completion: nil)
    }
}

class AppDockViewController: UIViewController {
    var appDockView: AppDockView? {
        return (navigationController as? AppDockNavigationController)?.appDockView
    }
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(image: R.image.cancel(), style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
        doneButton = UIBarButtonItem(image: R.image.batchDoneBarButton(), style: .done, target: self, action: #selector(self.doneButtonDidTap))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        appDockView?.items = appDockItems
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

        selectCurrentAppIfExist()
    }
    
    var appDockItems: [AppDockItem] {
        return AppCenter.default.apps(by: .default).map { AppDockItem(app: $0) }
    }

    @objc func cancelButtonDidTap(sender: Any) {
        appDockView?.closeDrawer()
    }

    @objc func doneButtonDidTap(sender: Any) {
        appDockView?.closeDrawer()
    }
    
    var appDockInsets: UIEdgeInsets {
        var insets = safeAreaInsets
        if let appDockView = appDockView {
            insets.bottom = appDockView.bounds.height - safeAreaInsets.bottom
        }
        return insets
    }
}

extension AppDockViewController {
    fileprivate func selectCurrentAppIfExist() {
        guard let currentApp = AppCenter.default.current, let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else { return }
        appDockView?.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0))
    }
}
