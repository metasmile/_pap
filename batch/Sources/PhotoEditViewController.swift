//
//  PhotoEditViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 6..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Hero
import AVFoundation
import Photos

protocol EditViewControllerDelegate {
    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<AppValue>?, at indexPath: IndexPath?)
}

class PhotoEditViewController: AppDockViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!

    var delegate: EditViewControllerDelegate?
    
    lazy var zoomingContentView: UIView = {
        return UIView(frame: view.bounds)
    }()
    
    lazy var assetView: AssetView = {
        return AssetView(frame: zoomingContentView.bounds)
    }()
    
    var placeholderImage: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            assetView.image = placeholderImage
            layoutAssetView()
        }
    }
    fileprivate var editItem = StateValueSet<AppValue>()
    var placeholderView: UIView?
    var indexPathInBatch: IndexPath?
    
    var asset: PHAsset?
    var preferredEditState = StateValueSet<AppValue>()
    
    var transitionID: String?

    let iOSStandardEditorBackgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
    var actionItems: [UIPreviewActionItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit".localized

        view.backgroundColor = iOSStandardEditorBackgroundColor

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = iOSStandardEditorBackgroundColor
        
        photoZoomingView.addSubview(zoomingContentView)
        
        assetView.contentMode = .scaleAspectFit
        assetView.hero.id = transitionID
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
//        editToolbar.borderColor = iOSStandardEditorBackgroundColor
//        editToolbar.toolbar.barStyle = .black
//        editToolbar.toolbar.tintColor = UIColor.white
//        editToolbar.toolbar.barTintColor = iOSStandardEditorBackgroundColor
        
        appDockView?.barStyle = .black

        doneButton?.title = "Done".localized
        
        assetView.image = placeholderImage
        assetView.preferredTransform = preferredEditState.transform
        assetView.applyFilter(ciFilter: preferredEditState.ciFilter)
        layoutAssetView()
        
        if let asset = asset {
            assetView.setAsset(asset, completion: { (result) in
                self.assetView.applyFilter(ciFilter: self.preferredEditState.ciFilter)
                if result is AVPlayerItem {
                    self.assetView.playVideoWithLooping()
                }
            })
        }
    }
    
    override var appDockItems: [AppDockItem] {
        guard let app = AppCenter.default.current else { return [] }
        return [AppDockItem(app: app)]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AppCenter.default.watch(\.currentIdentifier, id:"editor", options:[.new, .initial]) { appCenter, dict in

            appCenter.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"editor\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform{
                    self.addTransformItem(value)
                }
            }
            
            appCenter.currentInstanceAs(PhotosFilterApp.self)?.config?.watch(\.filter, id:"editor\(PhotosFilterApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.setFilter(value)
                }
            }

            //common ui attributes if current app is ConfigurableApp
            appCenter.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .white))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["editor\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.unwatch(\.filter, forIds:["editor\(PhotosFilterApp.info.identifier)"])
        AppCenter.default.unwatch(\.currentIdentifier, forIds:["editor"])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePreview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController {
            placeholderView?.removeFromSuperview()
        }
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
    
    private func addTransformItem(_ transformItem: AppValue) {
        editItem.append(transformItem)
        
        updatePreview()
    }
    
    private func setFilter(_ filterItem: AppValue) {
        editItem.append(filterItem)
        
        updatePreview()
    }
    
    private func updatePreview(_ completion: (() -> Void)? = nil) {
        layoutAssetView()
        
        self.assetView.applyFilter(ciFilter: self.editItem.ciFilter)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.assetView.layer.transform = self.editItem.transform3d
        }) { (finished) in
            completion?()
        }
    }
    
    // MARK: - Tool Bar Actions
    
    override func cancelButtonDidTap(sender: Any) {
        super.cancelButtonDidTap(sender: sender)
        
        editItem.reset()
        
        updatePreview { [unowned self] in
            self.delegate?.editViewController(self, didFinishWith: nil, at: self.indexPathInBatch)
        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        super.doneButtonDidTap(sender: sender)
        
        assetView.layer.transform = CATransform3DIdentity
        assetView.transform = editItem.transform
        placeholderView?.transform = editItem.transform

        delegate?.editViewController(self, didFinishWith: self.editItem, at: self.indexPathInBatch)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingContentView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UIView.animateUsingSpring(duration: 0.5, delay: 0, animations: {
            scrollView.zoomScale = 1
        }, completion: nil)
    }

    override var previewActionItems: [UIPreviewActionItem] {
        guard let actionItems = actionItems, actionItems.count > 0 else { return super.previewActionItems }
        return actionItems
    }
}
