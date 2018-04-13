//
//  PhotosFilter.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import DefaultsKit

public class PhotosFilterItem: AppValue {
    override var ciFilter: CIFilter? {
        return _filter
    }
    
    private var _filter: CIFilter?
    
    init(_ filter: CIFilter? = nil) {
        super.init()
        
        _filter = filter
    }
}

public extension StateValueSet where T: AppValue {
    var ciFilter: CIFilter? {
        return self.iterator().reversed().first?.ciFilter
    }
}

public class PhotosFilterAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var filter: AppValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? PhotosFilterAppConfig, let filter = other.filter{
            self.filter = filter
        }
    }
}

class _PhotosFilterAppAsset: PHAssetItem<AppValue> {}

public class PhotosFilterApp: NSObject, KeyPathWatchable, ConfigurableApp, _ConfigurableApp, AppDockControllableApp, PHAssetFinalizableApp, PersistableApp, PhotoPickerCollectionViewDisplayableApp, PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = _PhotosFilterAppTask.self
    public static let paramType:TaskParamable.Type = _PhotosFilterAppAsset.self
    
    public static var configure:(() -> PhotosFilterAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: PhotosFilterAppConfig? = PhotosFilterApp.configure?()
    public private(set) lazy var controller: AppDockContent? = createController()

    public static let info = AppInfo(
        identifier: "com.stells.batch.photosfilter"
        , version: "0.1"
        , phase: .beta
        , appType: PhotosFilterApp.self
        , displayName: "Photos Filter"
        , icon: R.image.revertAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
    }

    public func isItemEnables(for item: PHAssetItem<AppValue>) -> Bool {
        return (item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive)) || item.asset.mediaType == .video
    }
    
    public var finalizingOptions: PHAssetFinalizingOptions{
        return [.modify]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateControllerView()
    }
}

class CIAutoEnhancementFilter: CIFilter {
    init(name: String) {
        super.init()
        
        self.name = name
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        guard var image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        
        for filter in image.autoAdjustmentFilters() {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                image = result
            }
        }
        
        return image
    }
}

private extension PhotosFilterApp {
    private struct PhotosFilterNames {
        static let CIPhotoEffectChrome = "CIPhotoEffectChrome"
        static let CIPhotoEffectFade = "CIPhotoEffectFade"
        static let CIPhotoEffectInstant = "CIPhotoEffectInstant"
        static let CIPhotoEffectNoir = "CIPhotoEffectNoir"
        static let CIPhotoEffectProcess = "CIPhotoEffectProcess"
        static let CIPhotoEffectTonal = "CIPhotoEffectTonal"
        static let CIPhotoEffectTransfer = "CIPhotoEffectTransfer"
        static let CIAutoEnhancement = "AutoEnhancement"
        
        static func aliasName(_ filterName: String?) -> String? {
            switch filterName {
            case CIPhotoEffectChrome?: return "Chrome"
            case CIPhotoEffectFade?: return "Fade"
            case CIPhotoEffectInstant?: return "Instant"
            case CIPhotoEffectNoir?: return "Noir"
            case CIPhotoEffectProcess?: return "Process"
            case CIPhotoEffectTonal?: return "Tonal"
            case CIPhotoEffectTransfer?: return "Transfer"
            case CIAutoEnhancement?: return "Auto"
            default: return "Original"
            }
        }
    }
    
    struct CIFilters {
        static let CIPhotoEffectChrome = CIFilter(name: PhotosFilterNames.CIPhotoEffectChrome)
        static let CIPhotoEffectFade = CIFilter(name: PhotosFilterNames.CIPhotoEffectFade)
        static let CIPhotoEffectInstant = CIFilter(name: PhotosFilterNames.CIPhotoEffectInstant)
        static let CIPhotoEffectNoir = CIFilter(name: PhotosFilterNames.CIPhotoEffectNoir)
        static let CIPhotoEffectProcess = CIFilter(name: PhotosFilterNames.CIPhotoEffectProcess)
        static let CIPhotoEffectTonal = CIFilter(name: PhotosFilterNames.CIPhotoEffectTonal)
        static let CIPhotoEffectTransfer = CIFilter(name: PhotosFilterNames.CIPhotoEffectTransfer)
        static let CIAutoEnhancement = CIAutoEnhancementFilter(name:PhotosFilterNames.CIAutoEnhancement)
        
        static var filters: [CIFilter] {
            return [
                CIAutoEnhancement,
                CIPhotoEffectChrome,
                CIPhotoEffectFade,
                CIPhotoEffectInstant,
                CIPhotoEffectProcess,
                CIPhotoEffectTransfer,
                CIPhotoEffectTonal,
                CIPhotoEffectNoir
            ].compactMap({ $0 })
        }
    }
    
    private func createController() -> AppDockContent {
        var items = CIFilters.filters.map({ (filter) -> BatchUICollectionView.CollectionItem in
            return BatchUICollectionView.CollectionItem(title: PhotosFilterNames.aliasName(filter.name), image: nil, action: {
                self.config?.filter = PhotosFilterItem(filter)
            })
        })
        items.insert(BatchUICollectionView.CollectionItem(title: PhotosFilterNames.aliasName(nil), image: nil, action: { self.config?.filter = PhotosFilterItem() }), at: 0)
        
        let view = BatchUICollectionView(items: items)
        
        var p = AppDockContentPreferences()
        p.pinned = true
        p.height = 100 // for test. remove this line after fixed app design
        return AppDockContentItem(view: view, preferences: p)
    }
    
    private func updateControllerView(){
        self.controller?.view.tintColor = config?.tintColor
    }
}

class BatchUICollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    struct CollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?
    }
    
    private var items = [CollectionItem]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    init(items: [CollectionItem]) {
        self.init()
        
        initialize()
        
        self.items = items
        
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { (finished) in
            self.updateCollectionViewInsets()
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            collectionView.tintColor = tintColor
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: bounds, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = false
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.scrollsToTop = false
        view.backgroundColor = UIColor.clear
        view.register(BatchUICollectionViewCell.self, forCellWithReuseIdentifier: "BatchUICollectionViewCell")
        return view
    }()
    
    private func initialize() {
        addSubview(collectionView)
        collectionView.fitConstraints(to: self)
    }
    
    private func updateCollectionViewInsets() {
        collectionView.collectionViewLayout.prepare()
        let contentWidth = collectionView.collectionViewLayout.collectionViewContentSize.width
        var contentInset = collectionView.contentInset
        if contentWidth > collectionView.bounds.width {
            contentInset.left = 0
            contentInset.right = 0
        }
        else {
            let inset = (collectionView.bounds.width - contentWidth) / 2
            contentInset.left = inset
            contentInset.right = inset
        }
        
        collectionView.contentInset = contentInset
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BatchUICollectionViewCell", for: indexPath) as! BatchUICollectionViewCell
        cell.title = items[indexPath.item].title
        cell.image = items[indexPath.item].image
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        items[indexPath.item].action?()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}

class BatchUICollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: bounds)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: bounds)
        view.contentMode = .center
        return view
    }()
    
    private func initialize() {
        contentView.addSubview(imageView)
        imageView.fitConstraints(to: contentView)
        
        contentView.addSubview(titleLabel)
        titleLabel.fitConstraints(to: contentView)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        imageView.tintColor = tintColor
        titleLabel.textColor = tintColor
    }
}

private class _PhotoFilterButton: UIButton {
    var filter: CIFilter?
}

private class _PhotosFilterAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _PhotosFilterAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _PhotosFilterAppAsset)?.cancelAllRequestIDs()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        assert(param is _PhotosFilterAppAsset, "TaskParamable type of this app is \(_PhotosFilterAppAsset.self)")
        guard let _param = param as? _PhotosFilterAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _PhotosFilterAppAsset, _ async: AsyncManualSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async?.begin()
        
        assetItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }
        
        async?.waitUntilEnd()
        return result
    }
}
