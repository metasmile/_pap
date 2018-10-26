//
//  AppDockViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 4..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Intents
internal class AppDockContainerView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
    
}

class AppDockNavigationController: UINavigationController, UINavigationControllerDelegate {
    lazy var appDockView: AppDockView = {
        let view = AppDockView(frame: CGRect(origin: CGPoint(x: 0, y: self.view.bounds.height - 64), size: CGSize(width: self.view.bounds.width, height: 64)))
        return view
    }()
    
    lazy var appDockContainerView: AppDockContainerView = {
        return AppDockContainerView(frame: view.bounds)
    }()
    
    lazy var dimmedView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = .black
        view.alpha = 0.5
        view.isHidden = true
        return view
    }()
    
    private var appDockViewBottomLayout: NSLayoutConstraint?
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        view.addSubview(dimmedView)
        dimmedView.fitConstraints(to: view)
        
        view.addSubview(appDockContainerView)
        appDockContainerView.fitConstraints(to: view)
        
        appDockContainerView.addSubview(appDockView)
        
        appDockView.translatesAutoresizingMaskIntoConstraints = false
        appDockView.leadingAnchor.constraint(equalTo: appDockContainerView.leadingAnchor).isActive = true
        appDockView.trailingAnchor.constraint(equalTo: appDockContainerView.trailingAnchor).isActive = true
        appDockViewBottomLayout = appDockView.bottomAnchor.constraint(equalTo: appDockContainerView.bottomAnchor)
        appDockViewBottomLayout?.isActive = true
        
        if let pickerVC = R.storyboard.appStoryboard.photoPickerViewController() {
            pushViewController(pickerVC, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewControllers.filter({ $0.isViewLoaded }).forEach({ $0.viewDidLayoutSubviews() })
    }
    
    func setAppDockHidden(_ hidden: Bool, animated: Bool) {
        appDockViewBottomLayout?.constant = hidden ? appDockView.bounds.height : 0
        
        navigationBar.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.appDockView.superview?.layoutIfNeeded()
        }, completion: nil)
        
        interactivePopGestureRecognizer?.isEnabled = hidden
    }
    
    private var needsScrollToBottom = false
}

class AppDockViewController: UIViewController, mmcColorThemeable {
    var appDockView: AppDockView? {
        return (navigationController as? AppDockNavigationController)?.appDockView
    }
    
    var appDockNavigationController: AppDockNavigationController? {
        return (navigationController as? AppDockNavigationController)
    }
    
    lazy var cancelButton: UIBarButtonItem? = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
    lazy var doneButton: UIBarButtonItem? = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(self.doneButtonDidTap))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerThemeable()
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        installAppDockItems()
        
        appDockView?.dataSource = self
        appDockView?.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //INFO: for prevent unnecessary animation
        self.appDockView?.superview?.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isWatchingAppConfig {
            isWatchingAppConfig = true
            registerWatchingAppConfig()
        }

        SpotlightSearchAppDelegate.launchAppIfNeededWithSearchable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isWatchingAppConfig {
            isWatchingAppConfig = false
            unregisterWatchingAppConfig()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        appDockView?.invalidateCollectionViewLayout()
        
        if let appDockView = appDockView {
            content(in: appDockView)?.willLayoutSubviews()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //INFO: for update bottom inset
        self.appDockView?.superview?.layoutIfNeeded()
        
        if let appDockView = appDockView {
            content(in: appDockView)?.didLayoutSubviews()
        }
    }
    
    private var isWatchingAppConfig = false
    func registerWatchingAppConfig() {
        
    }
    
    func unregisterWatchingAppConfig() {
        
    }
    
    func appDidChange() {
        
    }

    //INFO: this function always called. for botch case
    // 1. appDidChange -> appDidAppear
    // 2. [Didn't change] -> appDidAppear
    func appDidAppear(){

    }
    
    var appDockItems: [AppDockItem] {
        return []
    }
    
    internal var appDockItemGroups = [[AppDockItem]]()

    @objc func cancelButtonDidTap(sender: Any) {
        if appDockView?.isContentLayoutMaximized == true {
            appDockView?.closeDrawer()
        }
    }

    @objc func doneButtonDidTap(sender: Any) {
        if appDockView?.isContentLayoutMaximized == true {
            appDockView?.closeDrawer()
        }
    }
    
    var appDockInsets: UIEdgeInsets {
        var insets = safeAreaInsets
        if let appDockView = appDockView {
            insets.bottom = appDockView.bounds.height - safeAreaInsets.bottom
        }
        return insets
    }
    
    func content(in view: AppDockView) -> AppDockContent? {
        return AppCenter.default.currentInstanceAs(AppDockApp.self)?.content
    }
    
    func applyTheme(_ colorTheme: mmcColorTheme) {
        appDockView?.barStyle = colorTheme.barStyle
    }
}

extension AppDockViewController: AppDockViewDataSource {
    fileprivate func installAppDockItems() {

        var appGroupIndexes = [String:Int]()
        for g in appDockItems.sorted(by:{ (item1, item2) -> Bool in
            return item1.app.group.priority < item2.app.group.priority

        }) where appGroupIndexes[g.app.group.identifier] == nil{
            appGroupIndexes[g.app.group.identifier] = appGroupIndexes.keys.count
        }

        appDockItemGroups = Array<[AppDockItem]>(repeating: [], count: appGroupIndexes.keys.count)

        for item in appDockItems {
            let section:Int
            if let indexOfGroupedApp = appGroupIndexes[item.app.group.identifier] {
                section = indexOfGroupedApp
            } else {
                section = 0
            }
            appDockItemGroups[section].append(item)
        }
    }

    func numberOfSections(in view: AppDockView) -> Int {
        return appDockItemGroups.count
    }
    
    func appDockView(_ view: AppDockView, numbefOfItemsInSection section: Int) -> Int {
        return appDockItemGroups[section].count
    }
    
    func appDockView(_ view: AppDockView, itemAt indexPath: IndexPath) -> AppDockItem? {
        return appDockItemGroups[safe: indexPath.section]?[safe: indexPath.item]
    }
}

extension AppDockViewController {
    func setViewControllerDisabled(_ disabled: Bool) {
        guard let dimmedView = appDockNavigationController?.dimmedView else { return }
        
        UIView.transition(with: dimmedView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            dimmedView.isHidden = !disabled
        }, completion: nil)
    }
    
    var isViewDisabled: Bool {
        return (appDockNavigationController?.dimmedView.isHidden ?? true) == false
    }
}
