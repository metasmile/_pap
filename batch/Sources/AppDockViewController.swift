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
    @IBOutlet weak var dimmedView: UIView!
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(image: R.image.cancel(), style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
        doneButton = UIBarButtonItem(image: R.image.batchDoneBarButton(), style: .done, target: self, action: #selector(self.doneButtonDidTap))
        
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

        selectCurrentAppIfExist()
    }
    
    var appDockItems: [AppDockItem] {
        return AppCenter.default.apps(by: .default).map { AppDockItem(app: $0) }
    }

    @objc func cancelButtonDidTap(sender: Any) {
        appDockView.closeDrawer()
    }

    @objc func doneButtonDidTap(sender: Any) {
        appDockView.closeDrawer()
    }
    
    var appDockInsets: UIEdgeInsets {
        var insets = safeAreaInsets
        insets.bottom = appDockView.bounds.height - safeAreaInsets.bottom
        return insets
    }
}

extension AppDockViewController {
    fileprivate func selectCurrentAppIfExist() {
        guard let currentApp = AppCenter.default.current, let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else { return }
        appDockView.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0))
    }
}

extension AppDockViewController: AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        AppCenter.default.current = item.app
        
        let configView = AppCenter.default.currentInstanceAs(UIControllableApp.self)?.controlView
        appDockView.setAppConfigView(configView)
        
        appDockView.closeDrawer(reloadsPreview: true)
    }
    
    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        UIView.transition(with: dimmedView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = !isOpened
        }, completion: nil)
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
