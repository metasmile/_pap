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

class PhotoEditorTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var presented: Bool = true
    
    var sourceView: UIView?
    var transitionView: UIView?
    var sourceRect: CGRect = .zero
    var targetRect: CGRect = .zero
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let toView = transitionContext.view(forKey: .to)
        
        if let view = toView {
            containerView.addSubview(view)
        }
        
        if let view = transitionView {
            containerView.addSubview(view)
        }
        
        if presented {
            self.sourceView?.isHidden = true
        }
        else if let appDockNavigationController = transitionContext.viewController(forKey: .from) as? AppDockNavigationController {
            if let photoEditor = appDockNavigationController.topViewController as? PhotoEditViewController {
                photoEditor.zoomingContentView.isHidden = true
            }
        }
        
        toView?.alpha = 0
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext) / 2) {
            toView?.alpha = 1
        }
        
        DispatchQueue.main.async {
            UIView.animateAsSpring(self.transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
                self.transitionView?.frame = self.presented ? self.targetRect : self.sourceRect
                
                if !self.presented {
                    self.transitionView?.clipsToBounds = true
                }
            }) { (completed) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        if !self.presented {
            self.sourceView?.isHidden = false
            self.sourceView = nil
        }
        
        self.transitionView?.removeFromSuperview()
        self.transitionView = nil
    }
}

protocol EditViewControllerDelegate {
    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<ImageEditStateValue>?, at indexPath: IndexPath?)
}

class PhotoEditViewController: AppDockViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!

    var delegate: EditViewControllerDelegate?
    
    lazy var zoomingContentView: UIView = {
        return UIView(frame: view.bounds)
    }()
    
    lazy var titleLabel: UILabel = UILabel(frame: .zero)
    
    lazy var titleView: UIView = {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .white
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(self.infoButtonDidTap), for: .touchUpInside)
        
        let view = UIStackView(arrangedSubviews: [titleLabel, infoButton] )
        view.axis = .horizontal
        view.spacing = 4
        
        return view
    }()
    
    lazy var assetView: AppUIAssetView = {
        return AppUIAssetView(frame: zoomingContentView.bounds)
    }()
    
    var placeholderImage: UIImage?
    lazy var placeholderView: UIImageView = {
        return UIImageView(frame: zoomingContentView.bounds)
    }()
    
    var assetItem: AppAsset?
    
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
        return UITapGestureRecognizer(target: self, action: #selector(self.tapGestureDidRecognize))
    }()
    
    @objc private func tapGestureDidRecognize(sender: UITapGestureRecognizer) {
        if let app = AppCenter.default.currentInstanceAs(PhotoEditorPreviewInteractionable.self) {
            let pointInAssetView = sender.location(in: assetView)
            let assetSize = assetView.size
            app.photoEditorPreviewDidTap(at: CGPoint(x: pointInAssetView.x / assetSize.width, y: pointInAssetView.y / assetSize.height), with: editItem.imageEditStateValue)
        }
        playOrPause()
    }
    
    private func playOrPause() {
        if assetView.isPlaying {
            assetView.pauseAny()
        }
        else {
            assetView.playAny()
        }
    }
    
    lazy var transitionAnimator = PhotoEditorTransitionAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = canEdit ? "Edit".localized : nil
        navigationItem.titleView = titleView
        
        zoomingContentView.isHidden = true
        
        photoZoomingView.canCancelContentTouches = false
        photoZoomingView.addSubview(zoomingContentView)
        
        placeholderView.image = placeholderImage
        placeholderView.contentMode = .scaleAspectFit
        zoomingContentView.addSubview(placeholderView)
        
        assetView.contentMode = .scaleAspectFit
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
        appDockView?.delegate = self

        doneButton.title = "Done".localized
        
        assetView.imageEditType = asset?.imageType ?? .notImage
        
        if canEdit {
            if let app = AppCenter.default.currentInstanceAs(PhotoEditorPreviewProcessableApp.self), let asset = asset {
                if asset.mediaType == .image {
                    let appAsset = AppAsset(asset)
                    appAsset.editState = preferredEditState
                    
                    assetView.imageEditType = app.photoEditorShouldPreview(item: appAsset) ? .stillImage : asset.imageType
                }
            }
            else if let _ = AppCenter.default.currentInstanceAs(EditableApp.self), let asset = asset {
                if asset.imageType == .livePhoto {
                    let appAsset = AppAsset(asset)
                    appAsset.editState = preferredEditState
                    
                    assetView.imageEditType = canEdit ? .notImage : asset.imageType
                }
            }
        }
        
        if let app = AppCenter.default.currentInstanceAs(AppDockApp.self) {
            app.dataSource = self
            app.reloadData()
        }
        
        assetView.isHidden = true
        assetView.asset = asset
        assetView.preferredTransform = preferredEditState.transform
        setEditState(preferredEditState)
        
        assetView.addGestureRecognizer(tapToPlayGesture)
        
        layoutAssetView()
        
        if let asset = asset {
            assetView.setAsset(asset, completion: {
                self.assetView.isHidden = false
                self.placeholderView.isHidden = true
                self.setEditState(self.preferredEditState)
                if asset.imageType == .livePhoto, !self.assetView.shouldEditImageAsStillImage {
                    if self.assetView.isProcessing {
                        self.assetView.isProcessing(false, animated: true)
                    }
                }
                self.assetView.playAny()
                
                if var playerControl = AppCenter.default.currentInstanceAs(PhotoEditorViewControllerDelegatableApp.self)?.photoEditorDockContent as? AppDockContentPlayerControllable {
                    playerControl.player = self.assetView.player
                }
            })
        }
    }
    
    override var appDockItems: [AppDockItem] {
        guard let app = AppCenter.default.current else { return [] }
        return [AppDockItem(app: app)]
    }
    
    override func content(in view: AppDockView) -> AppDockContent? {
        guard canEdit else { return nil }
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
        
        zoomingContentView.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isBeingDismissed {
            assetView.teardown()
            
            if var playerControl = AppCenter.default.currentInstanceAs(PhotoEditorViewControllerDelegatableApp.self)?.photoEditorDockContent as? AppDockContentPlayerControllable {
                playerControl.player = nil
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutAssetView()
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
        
        transitionAnimator.targetRect = view.convert(placeholderView.frame, from: zoomingContentView)
    }
    
    // MARK: - Navigation Bar Actions
    
    private func setEditState(_ editState: StateValueSet<ImageEditStateValue>) {
        guard canEdit else { return }
        
        if let app = AppCenter.default.currentInstanceAs(PhotoEditorPreviewProcessableApp.self), let asset = asset {
            let targetSize = self.assetView.size
            
            let appAsset = AppAsset(asset)
            appAsset.editState = editState
            
            app.previewProcessing(appAsset, targetSize: targetSize) { (original, filtered) in
                DispatchQueue.main.async {
                    if let image = app.previewOriginalImageCompare(with: appAsset, targetSize: targetSize) ?? original {
                        self.assetView.originalImageForCompare = image
                        self.assetView.originalBadgeTitle = app.previewOriginalBadgeTitle
                    }
                    
                    self.assetView.originalImage = original
                    self.assetView.filteredImage = filtered
                }
            }
        }
        else {
            assetView.applyEditState(editState)
        }
    }
    
    func appendImageEditState(_ value: ImageEditStateValue) {
        editItem.append(value)
        
        updatePreview()
    }
    
    private func updatePreview(_ completion: (() -> Void)? = nil) {
        layoutAssetView()
        
        self.setEditState(self.editItem)
        
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
        guard canEdit else {
            cancelButtonDidTap(sender: cancelButton)
            return
        }
        
        super.doneButtonDidTap(sender: sender)
        
        if editItem.hasChanges {
            var image = originalImage?.applyFilter(ciFilter: editItem.ciFilter) ?? originalImage
            if preferredEditState.transform != .identity {
                image = image?.applyTransform(preferredEditState.transform)
            }
            placeholderView.image = image
            placeholderView.transform = editItem.transform
        }
        
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

        appDidAppear()
    }

    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        setViewControllerDisabled(isOpened)
    }
}

extension PhotoEditViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.presented = true
        return transitionAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let imageView = UIImageView(frame: view.convert(placeholderView.frame, from: zoomingContentView))
        imageView.image = placeholderView.image
        imageView.contentMode = .scaleAspectFill
        imageView.transform = placeholderView.transform
        
        transitionAnimator.transitionView = imageView
        transitionAnimator.presented = false
        return transitionAnimator
    }
}

extension PhotoEditViewController {
    private var canEdit: Bool {
        if let app = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDelegatableApp.self), let assetItem = assetItem, !app.shouldSelect(item: assetItem) {
            return false
        }
        else {
            return true
        }
    }
}

extension PhotoEditViewController: AppDockAppDataSource {
    func numberOfAppAssets(in app: AppDockApp) -> Int {
        return assetItem == nil ? 0 : 1
    }
    
    func appDockApp(_ app: AppDockApp, appAssetAt index: Int) -> AppAsset? {
        return assetItem
    }
}

extension PhotoEditViewController {
    @objc func infoButtonDidTap(sender: UIButton) {
        let vc = PHAssetMetadataViewController()
        vc.asset = asset
        
        let nc = UINavigationController(rootViewController: vc)
        self.present(nc, animated: true, completion: nil)
    }
}

class PHAssetMetadataViewController: UIViewController, AppColorThemeable {
    private class MetadataTableViewCell: UITableViewCell {
        override func prepareForReuse() {
            super.prepareForReuse()
            
            textLabel?.text = nil
            detailTextLabel?.text = nil
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value2, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            textLabel?.textColor = .white
        }
    }
    
    private struct Metadata {
        var key: String
        var displayName: String
        var value: Any
    }
    
    private struct MetadataItem {
        var title: String
        private(set) var metadata: [Metadata]
        
        init(title: String, metadata: [Metadata]) {
            self.title = title
            self.metadata = metadata
        }
    }
    
    var asset: PHAsset?
    private var metadataItems: [MetadataItem] = []
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MetadataTableViewCell.self, forCellReuseIdentifier: "MetadataTableViewCell")
        tableView.allowsSelection = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.fitConstraints(to: view)
        
        registerThemeable()
        
        title = "Metadata".localized
        
        reloadMetadata()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeButtonDidTap)), animated: animated)
    }
    
    @objc private func closeButtonDidTap(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func reloadMetadata() {
        if let asset = asset, asset.mediaType == .image {
            reloadImageMetadata(with: asset)
        }
        else {
            
        }
    }
    
    private func reloadImageMetadata(with asset: PHAsset) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        
        asset.requestContentEditingInput(with: options) { (input, info) in
            guard let url = input?.fullSizeImageURL, let data = try? Data(contentsOf: url), let properties = data.getMetadata() else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            
            self.metadataItems = []
            
            var metadatas = [Metadata]()
            
            let filename = url.lastPathComponent
            metadatas.append(Metadata(key: "Filename", displayName: "File Name".localized, value: "\(filename)"))
            metadatas.append(Metadata(key: "Filetype", displayName: "File Type".localized, value: "\(UTI(withURL: url).rawValue)"))
            
            let dataFormatter = ByteCountFormatter()
            dataFormatter.countStyle = .binary
            
            metadatas.append(Metadata(key: "Filesize", displayName: "File Size".localized, value: "\(dataFormatter.string(fromByteCount: Int64(data.count)))"))
            
            if let date = asset.creationDate {
                metadatas.append(Metadata(key: "Date", displayName: "Date".localized, value: "\(dateFormatter.string(from: date))"))
            }
            
            if let pixelWidth = properties[ImageMetadata.PixelWidth], let pixelHeight = properties[ImageMetadata.PixelHeight] {
                metadatas.append(Metadata(key: "PixelSize", displayName: "Size".localized, value: "\(pixelWidth)x\(pixelHeight)"))
            }
            
            if let profileName = properties[ImageMetadata.ProfileName] {
                metadatas.append(Metadata(key: ImageMetadata.ProfileName, displayName: "Profile Name".localized, value: profileName))
            }
            
            if !metadatas.isEmpty {
                let metadataItem = MetadataItem(title: "File".localized, metadata: metadatas)
                self.metadataItems.append(metadataItem)
            }
            
            if let info = properties[ImageMetadata.Dictionary.TIFF] as? [String: Any] {
                var metadatas = [Metadata]()
                
                if let value = info[ImageMetadata.Property.TIFFModel] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.TIFFModel, displayName: "Model".localized, value: "\(value)"))
                }
                
                if !metadatas.isEmpty {
                    let metadataItem = MetadataItem(title: "TIFF".localized, metadata: metadatas)
                    self.metadataItems.append(metadataItem)
                }
            }
            
            if let info = properties[ImageMetadata.Dictionary.Exif] as? [String: Any] {
                var metadatas = [Metadata]()
                
                if let value = info[ImageMetadata.Property.ExifFocalLenIn35mmFilm] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.ExifFocalLenIn35mmFilm, displayName: "Focal Length".localized, value: "\(value) mm (in 35 mm)"))
                }
                
                if let value = (info[ImageMetadata.Property.ExifISOSpeedRatings] as? [Any])?.first {
                    metadatas.append(Metadata(key: ImageMetadata.Property.ExifISOSpeedRatings, displayName: "ISO".localized, value: "\(value)"))
                }
                
                if let value = info[ImageMetadata.Property.ExifFNumber] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.ExifFNumber, displayName: "Aperture".localized, value: "ƒ/\(value)"))
                }
                
                if let value = info[ImageMetadata.Property.ExifLensMake] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.ExifLensMake, displayName: "Lens Maker".localized, value: "\(value)"))
                }
                
                if let value = info[ImageMetadata.Property.ExifLensModel] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.ExifLensModel, displayName: "Lens Model".localized, value: "\(value)"))
                }
                
                if !metadatas.isEmpty {
                    let metadataItem = MetadataItem(title: "EXIF".localized, metadata: metadatas)
                    self.metadataItems.append(metadataItem)
                }
            }
            
            if let info = properties[ImageMetadata.Dictionary.GPS] as? [String: Any] {
                var metadatas = [Metadata]()
                
                if let lat = info[ImageMetadata.Property.GPSLatitude] as? Double, let lon = info[ImageMetadata.Property.GPSLongitude] as? Double {
                    let _ = CLLocationCoordinate2DMake(lat, lon)
                }
                
                if let value = info[ImageMetadata.Property.GPSLatitude] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.GPSLatitude, displayName: "Latitude".localized, value: "\(value)"))
                }
                
                if let value = info[ImageMetadata.Property.GPSLongitude] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.GPSLongitude, displayName: "Longitude".localized, value: "\(value)"))
                }
                
                if let value = info[ImageMetadata.Property.GPSAltitude] {
                    metadatas.append(Metadata(key: ImageMetadata.Property.GPSAltitude, displayName: "Altitude".localized, value: "\(value)"))
                }
                
                if !metadatas.isEmpty {
                    let metadataItem = MetadataItem(title: "GPS".localized, metadata: metadatas)
                    self.metadataItems.append(metadataItem)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func applyTheme(_ colorTheme: AppColorTheme) {
        tableView.tintColor = colorTheme.tintColor
    }
}

extension PHAssetMetadataViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return metadataItems.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let metadataItem = metadataItems[safe: section] else { return 0 }
        return metadataItem.metadata.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MetadataTableViewCell") as? MetadataTableViewCell ?? UITableViewCell()
        guard let metadataItem = metadataItems[safe: indexPath.section], let metadata = metadataItem.metadata[safe: indexPath.row] else { return cell }
        
        cell.detailTextLabel?.textColor = view.colorTheme.textGrayColor
        
        cell.textLabel?.text = metadata.displayName
        
        if let value = (metadata.value as? [Any])?.first {
            cell.detailTextLabel?.text = "\(value)"
        }
        else {
            cell.detailTextLabel?.text = "\(metadata.value)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return metadataItems[safe: section]?.title
    }
}

extension PHAssetMetadataViewController: UITableViewDelegate {
    
}
