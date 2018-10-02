//
//  PhotoEditViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 6..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Hero

protocol EditViewControllerDelegate {
    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<ImageEditStateValue>?, at indexPath: IndexPath?)
}

class PhotoEditViewController: AppDockViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!

    var delegate: EditViewControllerDelegate?
    
    lazy var zoomingContentView: UIView = {
        return UIView(frame: view.bounds)
    }()
    
    lazy var assetView: AppUIAssetView = {
        return AppUIAssetView(frame: zoomingContentView.bounds)
    }()
    
    var placeholderImage: UIImage?
    lazy var placeholderView: UIImageView = {
        return UIImageView(frame: zoomingContentView.bounds)
    }()
    
    fileprivate var editItem = StateValueSet<ImageEditStateValue>()

    var indexPathInPicker: IndexPath?
    var selectedInPicker: Bool = false
    var asset: PHAsset?
    var preferredEditState = StateValueSet<ImageEditStateValue>()
    
    var transitionID: String?

    let iOSStandardEditorBackgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
    var actionItems: [UIPreviewActionItem]?
    
    var originalImage: UIImage? {
        return assetView.originalImage
    }
    
    lazy var tapToPlayGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self.assetView, action: #selector(self.assetView.playAny))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit".localized

        view.backgroundColor = iOSStandardEditorBackgroundColor

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = iOSStandardEditorBackgroundColor
        
        photoZoomingView.canCancelContentTouches = false
        photoZoomingView.addSubview(zoomingContentView)
        
        placeholderView.image = placeholderImage
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.hero.id = "TransitionToPhotoEditViewController"
        zoomingContentView.addSubview(placeholderView)
        
        assetView.contentMode = .scaleAspectFit
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
        appDockView?.barStyle = .black
        appDockView?.delegate = self

        doneButton?.title = "Done".localized
        
        assetView.isHidden = true
        assetView.asset = asset
        assetView.preferredTransform = preferredEditState.transform
        assetView.applyEditState(preferredEditState)
        
        assetView.addGestureRecognizer(tapToPlayGesture)
        
        layoutAssetView()
        
        if let asset = asset {
            assetView.setAsset(asset, completion: {
                self.assetView.isHidden = false
                self.placeholderView.isHidden = true
                self.assetView.applyEditState(self.preferredEditState)
            })
        }
    }
    
    override var appDockItems: [AppDockItem] {
        guard let app = AppCenter.default.current else { return [] }
        return [AppDockItem(app: app)]
    }
    
    override func content(in view: AppDockView) -> AppDockContent? {
        return AppCenter.default.currentInstanceAs(PhotoEditorViewControllerDelegatableApp.self)?.photoEditorDockContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appDockNavigationController?.setAppDockHidden(false, animated: animated)
        AppCenter.default.openCurrentApp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let app = AppCenter.default.currentInstanceAs(EditableApp.self) {
            app.selectEditStateValue(self.preferredEditState.imageEditStateValue, in: (app as? PhotoEditorViewControllerDelegatableApp)?.photoEditorDockContent)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutAssetView()
    }
    
    override func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, id:"editor", options:[.new, .initial]) { appCenter, dict in
            
            appCenter.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"editor\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform{
                    self.setAppValue(value)
                }
            }
            
            appCenter.currentInstanceAs(FiltersApp.self)?.config?.watch(\.filter, id:"editor\(FiltersApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.setAppValue(value)
                }
            }
            
            appCenter.currentInstanceAs(AutoEditorApp.self)?.config?.watch(\.filter, id:"editor\(AutoEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.setAppValue(value)
                }
            }
            
            appCenter.currentInstanceAs(Stabilizer.self)?.config?.watch(\.stabilizationMode, id:"editor\(Stabilizer.info.identifier)") { (config, changed) in
                if let value = config.stabilizationMode {
                    self.setAppValue(value)
                }
            }
            
            //common ui attributes if current app is ConfigurableApp
            appCenter.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttribute(tintColor: .white))
        }
    }
    
    override func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["editor\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.unwatch(\.filter, forIds:["editor\(FiltersApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.unwatch(\.filter, forIds:["editor\(AutoEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.unwatch(\.stabilizationMode, forIds:["editor\(Stabilizer.info.identifier)"])
        AppCenter.default.unwatch(\.currentIdentifier, forIds:["editor"])
    }
    // MARK: - Layout
    
    func layoutAssetView() {
        guard let asset = asset else { return }
        let preferredSize = asset.pixelSize.applying(preferredEditState.transform).magnitude
        
        var boundingInsets = appDockInsets
        if #available(iOS 11.0, *) {
            boundingInsets.bottom += safeAreaInsets.bottom
        }
        
        let boundingBox = photoZoomingView.bounds.inset(by: boundingInsets)

        let actualContentSize = preferredSize.applying(editItem.transform).magnitude.aspectFit(in: boundingBox.size)
        let contentSize = actualContentSize.applying(editItem.transform.inverted()).magnitude
        
        zoomingContentView.frame.size = contentSize
        
        assetView.frame.origin = .zero
        assetView.frame.size = contentSize
        photoZoomingView.contentSize = actualContentSize
        
        zoomingContentView.center = CGPoint(x: boundingBox.width / 2, y: boundingBox.height / 2)
        assetView.center = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
        
        placeholderView.frame = assetView.frame
    }
    
    // MARK: - Navigation Bar Actions
    
    private func setAppValue(_ value: ImageEditStateValue) {
        editItem.append(value)
        
        updatePreview()
    }
    
    private func updatePreview(_ completion: (() -> Void)? = nil) {
        layoutAssetView()
        
        self.assetView.applyEditState(self.editItem)
        
        UIView.animateAsSpring(0.3, delay: 0.0, animations: {
            self.assetView.layer.transform = self.editItem.transform3d
        }) { (finished) in
            completion?()
        }
    }
    
    // MARK: - Tool Bar Actions
    
    override func cancelButtonDidTap(sender: Any) {
        super.cancelButtonDidTap(sender: sender)
        
        editItem = preferredEditState
        
//        updatePreview { [unowned self] in
            self.delegate?.editViewController(self, didFinishWith: nil, at: self.indexPathInPicker)
//        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        super.doneButtonDidTap(sender: sender)
        
        if let filter = editItem.ciFilter {
            placeholderView.image = originalImage?.applyFilter(ciFilter: filter)
        }
        
        placeholderView.transform = editItem.transform
        
        delegate?.editViewController(self, didFinishWith: self.editItem, at: self.indexPathInPicker)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingContentView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UIView.animateAsSpring(0.5, delay: 0, animations: {
            scrollView.zoomScale = 1
        }, completion: nil)
    }

    override var previewActionItems: [UIPreviewActionItem] {
        guard let actionItems = actionItems, actionItems.count > 0 else { return super.previewActionItems }
        return actionItems
    }
}


extension PhotoEditViewController: AppDockViewDelegate{
    func appDockView(_ view: AppDockView, needsScrollToBottom: Bool) {}

    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        let willAppChange = AppCenter.default.current != item.app

        AppCenter.default.current = item.app

        view.loadControllerContentIfNeeded()

        if willAppChange {
            appDidChange()
        }
        else {
            if appDockView?.contentLayoutState == .minimized {
                appDockView?.openDrawer()
            }
        }
    }

    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        setViewControllerDisabled(isOpened)
    }
}

// MARK: - Photos


