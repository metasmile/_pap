//
//  AppDockViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 4..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit

internal class AppDockContainerView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
}

class AppDockNavigationController: UINavigationController, UINavigationControllerDelegate {
    lazy var appDockView: AppDockView = {
        let view = AppDockView(frame: CGRect(origin: CGPoint(x: 0, y: self.view.bounds.height - 64), size: CGSize(width: self.view.bounds.width, height: 64)))
        view.delegate = self
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
        
        self.setViewControllers([
            R.storyboard.appStoryboard.photoAlbumViewController(),
            R.storyboard.appStoryboard.photoPickerViewController()
        ].compactMap { $0 }, animated: false)
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewControllers.forEach({ $0.viewDidLayoutSubviews() })
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

extension AppDockNavigationController: AppDockViewDelegate {
    func appDockView(_ view: AppDockView, needsScrollToBottom: Bool) {
        self.needsScrollToBottom = needsScrollToBottom
    }
    
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        if AppCenter.default.current != item.app {
            AppCenter.default.current = item.app
            
            appDockView.app = AppCenter.default.currentInstanceAs(AppDockApp.self)
            //INFO: by apps? or globally? hmm at first following imessage policy(global)
            
            if let vc = self.topViewController as? AppDockViewController {
                vc.appDidChange()
            }
        }
        else {
            appDockView.app = AppCenter.default.currentInstanceAs(AppDockApp.self)

            var needsToOpenDockViewDrawer = false

            if let collectionView = self.topViewController?.view.subviews.first as? UICollectionView {
                let bottomOffsetY = collectionView.contentSize.height - collectionView.bounds.size.height + collectionView.adjustedContentInset.bottom

                if collectionView.contentOffset.y == bottomOffsetY{
                    needsToOpenDockViewDrawer = true
                }
                else if needsScrollToBottom {
                    needsScrollToBottom = false
                    collectionView.setContentOffset(CGPoint(x: 0, y: bottomOffsetY), animated: true)
                }

            }else{
                needsToOpenDockViewDrawer = true
            }

            if needsToOpenDockViewDrawer && appDockView.contentLayoutState == .minimized {
                appDockView.openDrawer()
            }
        }
    }
    
    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        UIView.transition(with: dimmedView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = !isOpened
        }, completion: nil)
    }
}

class AppDockViewController: UIViewController, AppDockViewDataSource {
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

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        appDockView?.dataSource = self
        appDockView?.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController?.navigationBar.barStyle == UIBarStyle.black {
            cancelButton?.tintColor = .white
            doneButton?.tintColor = .white
        }
        else {
            cancelButton?.tintColor = view.tintColor
            doneButton?.tintColor = view.tintColor
        }
        
        //INFO: for prevent unnecessary animation
        self.appDockView?.superview?.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        registerWatchingAppConfig()

        SpotlightSearchAppDelegate.launchAppIfNeededWithSearchable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unregisterWatchingAppConfig()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //INFO: for update bottom inset
        self.appDockView?.superview?.layoutIfNeeded()
    }
    
    func registerWatchingAppConfig() {
        
    }
    
    func unregisterWatchingAppConfig() {
        
    }
    
    func appDidChange() {
        
    }
    
    var appDockItems: [AppDockItem] {
        return []
    }

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
    
    func dockContent(in view: AppDockView) -> AppDockContent? {
        return AppCenter.default.currentInstanceAs(AppDockApp.self)?.dockContent
    }
}

extension AppDockViewController {
    //MARK: - AppDockViewDataSource
    
    func numberOfItems(in view: AppDockView) -> Int {
        return appDockItems.count
    }
    
    func appDockView(_ view: AppDockView, itemAt index: Int) -> AppDockItem? {
        return appDockItems[safe: index]
    }
}
