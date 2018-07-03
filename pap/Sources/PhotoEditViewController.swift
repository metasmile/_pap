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
    
    fileprivate var editItem = StateValueSet<ImageEditStateValue>()

    var indexPathInPicker: IndexPath?
    var selectedInPicker: Bool = false
    var asset: PHAsset?
    var preferredEditState = StateValueSet<ImageEditStateValue>()
    
    var transitionID: String?

    let iOSStandardEditorBackgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
    var actionItems: [UIPreviewActionItem]?
    
    var originalImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit".localized

        view.backgroundColor = iOSStandardEditorBackgroundColor

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = iOSStandardEditorBackgroundColor
        
        photoZoomingView.addSubview(zoomingContentView)
        
        assetView.contentMode = .scaleAspectFit
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
        appDockView?.barStyle = .black

        doneButton?.title = "Done".localized
        
        assetView.hero.id = "TransitionToPhotoEditViewController"
        
        assetView.asset = asset
        assetView.preferredTransform = preferredEditState.transform
        assetView.applyEditState(preferredEditState)
        
        layoutAssetView()
        
        if let asset = asset {
            assetView.setAsset(asset, completion: {
                self.originalImage = self.assetView.image
                self.assetView.applyEditState(self.preferredEditState)
                self.assetView.playVideoWithLooping()
            })
        }
    }
    
    override var appDockItems: [AppDockItem] {
        guard let app = AppCenter.default.current else { return [] }
        return [AppDockItem(app: app)]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appDockNavigationController?.setAppDockHidden(false, animated: animated)
        selectCurrentAppIfExist(animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePreview()
    }
    
    override func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, id:"editor", options:[.new, .initial]) { appCenter, dict in
            
            appCenter.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"editor\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform{
                    self.setAppValue(value)
                }
            }
            
            appCenter.currentInstanceAs(PhotosFilterApp.self)?.config?.watch(\.filter, id:"editor\(PhotosFilterApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.setAppValue(value)
                }
            }
            
            appCenter.currentInstanceAs(AutoAdjustmentApp.self)?.config?.watch(\.filter, id:"editor\(AutoAdjustmentApp.info.identifier)") { (config, changed) in
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
            appCenter.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .white))
        }
    }
    
    override func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["editor\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.unwatch(\.filter, forIds:["editor\(PhotosFilterApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoAdjustmentApp.self)?.config?.unwatch(\.filter, forIds:["editor\(AutoAdjustmentApp.info.identifier)"])
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
        
        let boundingBox = UIEdgeInsetsInsetRect(photoZoomingView.bounds, boundingInsets)

        let actualContentSize = preferredSize.applying(editItem.transform).magnitude.aspectFit(in: boundingBox.size)
        let contentSize = actualContentSize.applying(editItem.transform.inverted()).magnitude
        
        zoomingContentView.frame.size = contentSize
        
        assetView.frame.origin = .zero
        assetView.frame.size = contentSize
        photoZoomingView.contentSize = actualContentSize
        
        zoomingContentView.center = CGPoint(x: boundingBox.width / 2, y: boundingBox.height / 2)
        assetView.center = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
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
        
        updatePreview { [unowned self] in
            self.delegate?.editViewController(self, didFinishWith: nil, at: self.indexPathInPicker)
        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        super.doneButtonDidTap(sender: sender)
        
        assetView.layer.transform = CATransform3DIdentity
        assetView.transform = editItem.transform

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
