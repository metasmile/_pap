//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public enum PHAssetFinalizingAction: Int{
    case modify
    case create
    case delete
    case share
    case actions
}

public protocol PHAssetFinalizableApp: FinalizableApp {
    var finalizingActions: [PHAssetFinalizingAction] {get}
}

extension PHAssetFinalizableApp{
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.share]
    }
}

extension PHAssetFinalizableApp {

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let finalizingActions = self.finalizingActions

        // filter only completed.
        let result = result.filter { respondable in respondable.info.state == .completed }

        // map target assets
        let targetResultAssets = result.compactMap {
            $0.result as? PHAssetResultable
        }

        if targetResultAssets.count == 0{
            return result
        }

        let exclusiveOption = finalizingActions.count==1
        for option in finalizingActions{
            if option == .delete{
                self.deletingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .modify{
                self.modifyingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .create{
                self.creatingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .share{
                self.sharingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .actions {
                self.showingActionsAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }
        }
        assert(asyncSignal.began == false)
        return result
    }

    internal func modifyingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            for result in targetResultAssets{
                PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
            }

        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("modifyingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    internal func deletingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(targetResultAssets.map { $0.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    internal func sharingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        if let _ = UIViewController.presentable {
            asyncSignal.begin()
            DispatchQueue.global().async {

                let activityItems = targetResultAssets.compactMap { (resultable: PHAssetResultable) -> Any? in
                    return self.routeUIActivityShareItems(by:resultable)
                }
                
                UIActivityViewController.share(activityItems: activityItems) { _, _, _, _ in
                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
        }
    }
    
    internal func sharingAndWait(from assetIdentifiers :[String], _ asyncSignal: AsyncWaitSignalable){
        if let _ = UIViewController.presentable {
            var activityItems = [Any]()
            
            asyncSignal.begin()
            DispatchQueue.global().async {
                PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil).enumerateObjects({ (asset, idx, stop) in
                    autoreleasepool {
                        if let item = asset.activityItemForActivityViewController() {
                            activityItems.append(item)
                        }
                    }
                })

                UIActivityViewController.share(activityItems: activityItems) { _, _, _, _ in
                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
        }
    }

    @discardableResult
    internal func creatingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable) -> [PHObjectPlaceholder] {
        var createdAssets = [PHObjectPlaceholder]()
        
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            for result in targetResultAssets{
                let request = PHAssetCreationRequest.forAsset()
                result.editingResultItems?.forEach {
                    request.addResource(with: $0.resourceType, fileURL: $0.url, options: nil)
                }
                if let createdAsset = request.placeholderForCreatedAsset {
                    createdAssets.append(createdAsset)
                }
            }

        }, completionHandler: { (success, info) in
            assert(success,"PHAssetFinalizableApp.creatingAndWait -> failed")
            asyncSignal.end()
        })
        asyncSignal.waitUntilEnd()
        
        return createdAssets
    }


    internal func showingActionsAndWait(targetResultAssets:[PHAssetResultable], excludedActions: [PHAssetFinalizingAction] = [], _ asyncSignal: AsyncWaitSignalable){
        let actionQueue = DispatchQueue.global()
        let actionSignal = AsyncSignal()
        
        var excludedActions = excludedActions
        
        //INFO: can not export live photo
        if targetResultAssets.contains(where: { $0.editingResultItems?.isLivePhoto == true }) {
            excludedActions.append(.share)
        }
        
        let vc = PHAssetEditingResultViewController()
        vc.title = "Export".localized
        
        let nc = UINavigationController(rootViewController: vc)
        
        vc.editingResults = targetResultAssets
        vc.didDismissHandler = {
            asyncSignal.end()
        }
        
        var exportOptionItems = [PHAssetEditingResultViewController.ExportOptionItem]()
        if !excludedActions.contains(.create) {
            exportOptionItems.append(PHAssetEditingResultViewController.ExportOptionItem("Save".localized, description: "Create and save as new to your photos".localized.localizedCapitalized, action: { signal in
                signal?.begin()
                actionQueue.async{
                    self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    signal?.end()
                }
                signal?.waitUntilEnd()
            }))
        }
        if !excludedActions.contains(.share) {
            exportOptionItems.append(PHAssetEditingResultViewController.ExportOptionItem("Share".localized, description: "Share directly without saving or modifying".localized.localizedCapitalized, action: { signal in
                signal?.begin()
                actionQueue.async{
                    self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    signal?.end()
                }
                signal?.waitUntilEnd()
            }))
        }
        if !excludedActions.contains(.modify) {
            exportOptionItems.append(PHAssetEditingResultViewController.ExportOptionItem("Modify".localized, description: "Modify the selected items".localized.localizedCapitalized, action: { signal in
                signal?.begin()
                actionQueue.async{
                    self.modifyingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    signal?.end()
                }
                signal?.waitUntilEnd()
            }))
        }
        if !excludedActions.contains(.share) && !excludedActions.contains(.create) {
            exportOptionItems.append(PHAssetEditingResultViewController.ExportOptionItem("Save and Share".localized, description: "Share directly after saving".localized.localizedCapitalized, action: { signal in
                signal?.begin()
                actionQueue.async{
                    let assets = self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    self.sharingAndWait(from: assets.map({ $0.localIdentifier }), actionSignal)
                    signal?.end()
                }
                signal?.waitUntilEnd()
            }))
        }
        vc.exportOptionItems = exportOptionItems
        
        asyncSignal.begin()
        
        DispatchQueue.main.async{
            UIViewController.present(nc, animated: true)
        }
        
        asyncSignal.waitUntilEnd()
    }

    private func routeUIActivityShareItems(by result:PHAssetResultable) -> Any?{
        /*
        case photo
        case video
        case audio
        case alternatePhoto
        case fullSizePhoto
        case fullSizeVideo
        case adjustmentData
        case adjustmentBasePhoto
        case pairedVideo
        case fullSizePairedVideo
        case adjustmentBasePairedVideo
        */

        /*
        UTItype

        https://developer.apple.com/documentation/mobilecoreservices/uttype
        https://developer.apple.com/documentation/mobilecoreservices/uttype/uti_image_content_types

        kUTTypeImage
        kUTTypeJPEG
        kUTTypeJPEG2000
        kUTTypeTIFF
        kUTTypePICT
        kUTTypeGIF
        kUTTypePNG
        kUTTypeQuickTimeImage
        kUTTypeAppleICNS
        kUTTypeBMP
        kUTTypeICO
        */
        
        if result.editingResultItems?.count == 1, let editingResultItem = result.editingResultItems?.first {
            return editingResultItem.url
        }
        else if result.editingResultItems?.isLivePhoto == true, let photo = result.editingResultItems?.item(for: .photo), let _ = result.editingResultItems?.item(for: .pairedVideo) {
            //INFO: not work to share live photos
//            var result: PHLivePhoto?
//            let async = AsyncSignal()
//            async.begin()
//            LivePhotoWriter().createLivePhoto(imageURL: photo.url, withPairedVideo: video.url) { (livePhoto) in
//                result = livePhoto
//                async.end()
//            }
//            async.waitUntilEnd()
//            return result
            return photo.url
        }
        else {
            return nil
        }
    }
}

private class PHAssetEditingResultViewController: UIViewController {
    // preview collection view (with urls)
    // export options
    // - create
    // - modify
    // - share
    
    class ExportOptionItem {
        var title: String
        var action: ((AsyncWaitSignalable?) -> Void)?
        var description: String?
        
        private(set) var exported: Bool = false
        
        init(_ title: String, description: String? = nil, action: ((AsyncWaitSignalable?) -> Void)?) {
            self.title = title
            self.description = description
            self.action = action
        }
        
        func markAsExported() {
            exported = true
        }
    }
    
    private lazy var collectionViewLayout: PHAssetEditingResultCollectionLayout = {
        let layout = PHAssetEditingResultCollectionLayout()
        layout.minimumSpacing = 8
        layout.dataSource = self
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceHorizontal = true
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PHAssetEditingResultCollectionViewCell.self, forCellWithReuseIdentifier: "\(PHAssetEditingResultCollectionViewCell.self)")
        return collectionView
    }()
    
    private lazy var exportOptionView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.rowHeight = 64
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PHAssetEditingResultExportOptionCell.self, forCellReuseIdentifier: "ExportOptionCell")
        return tableView
    }()
    
    var editingResults: [PHAssetResultable]?
    var exportOptionItems: [ExportOptionItem]?
    
    var didDismissHandler: (() -> Void)?
    
    var initialTargetIndexPath: IndexPath?
}

extension PHAssetEditingResultViewController: PHAssetEditingResultCollectionLayoutDataSource {
    func appAssetInAssetEditingResultCollectionLayout(_ layout: PHAssetEditingResultCollectionLayout, at indexPath: IndexPath) -> AppAsset? {
        return editingResults?[indexPath.item].appAsset
    }
}

extension PHAssetEditingResultViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !(editingResults ?? []).isEmpty {
            initialTargetIndexPath = IndexPath(item: 0, section: 0)
        }
        
        registerThemeable()
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3).isActive = true
        
        view.addSubview(exportOptionView)
        exportOptionView.translatesAutoresizingMaskIntoConstraints = false
        exportOptionView.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        exportOptionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        exportOptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        exportOptionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.cancelButtonDidTap))
        navigationItem.setRightBarButton(cancelButton, animated: true)
    }
    
    @objc private func cancelButtonDidTap(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: self.didDismissHandler)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

private class PHAssetEditingResultExportOptionCell: UITableViewIndicatorCell {
    lazy var indicatorView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        indicatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        indicatorView.widthAnchor.constraint(equalTo: indicatorView.heightAnchor, multiplier: 0.75).isActive = true
        
        detailTextLabel?.textColor = UIColor.gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PHAssetEditingResultViewController: UITableViewDataSource {
    var formattedResultItemString: String {
        var itemNumbers = [String]()
        if let items = editingResults?.filter({ $0.editingResultItems?.isStillPhoto == true }), !items.isEmpty {
            if let animatedItems = editingResults?.filter({ $0.editingResultItems?.isGIFImage == true }), !animatedItems.isEmpty {
                print(#function, animatedItems, animatedItems.count, animatedItems.count.decimalStyleString)
                if animatedItems.count == items.count {
                    itemNumbers.append(animatedItems.count == 1 ? "%@ Animated Image".localizedFormatted(animatedItems.count.decimalStyleString) : "%@ Animated Images".localizedFormatted(animatedItems.count.decimalStyleString))
                }
                else {
                    itemNumbers.append(items.count == 1 ? "%@ Photo".localizedFormatted(items.count.decimalStyleString) : "%@ Photos".localizedFormatted(items.count.decimalStyleString))
                    itemNumbers.append(animatedItems.count == 1 ? "%@ Animated Image".localizedFormatted(animatedItems.count.decimalStyleString) : "%@ Animated Images".localizedFormatted(animatedItems.count.decimalStyleString))
                }
            }
            else {
                itemNumbers.append(items.count == 1 ? "%@ Photo".localizedFormatted(items.count.decimalStyleString) : "%@ Photos".localizedFormatted(items.count.decimalStyleString))
            }
        }
        
        if let items = editingResults?.filter({ $0.editingResultItems?.isVideo == true }), !items.isEmpty {
            itemNumbers.append(items.count == 1 ? "%@ Video".localizedFormatted(items.count.decimalStyleString) : "%@ Videos".localizedFormatted(items.count.decimalStyleString))
        }
        
        if let items = editingResults?.filter({ $0.editingResultItems?.isLivePhoto == true }), !items.isEmpty {
            itemNumbers.append(items.count == 1 ? "%@ Live Photo".localizedFormatted(items.count.decimalStyleString) : "%@ Live Photos".localizedFormatted(items.count.decimalStyleString))
        }
        
        return itemNumbers.joined(separator: ", ")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exportOptionItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = exportOptionItems?[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExportOptionCell") ?? PHAssetEditingResultExportOptionCell(style: .subtitle, reuseIdentifier: "ExportOptionCell")
        cell.textLabel?.text = item?.title
        cell.detailTextLabel?.text = item?.description
        cell.accessoryType = item?.exported == true ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Choose an export option for %@".localizedFormatted(formattedResultItemString)
    }
}

extension PHAssetEditingResultViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIFeedback.select()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! PHAssetEditingResultExportOptionCell
        cell.accessoryType = .none
        cell.startIndicating(targetSubview: cell.indicatorView)
        
        let item = exportOptionItems?[indexPath.row]
        
        DispatchQueue(label: #file + #function, qos: .utility).async {
            item?.action?(AsyncSignal())
            item?.markAsExported()
            
            DispatchQueue.main.async {
                cell.stopIndicating(targetSubview: cell.indicatorView)
                cell.accessoryType = .checkmark
            }
        }
    }
}

extension PHAssetEditingResultViewController: AppColorThemeable {
    func applyTheme(_ colorTheme: AppColorTheme) {
        exportOptionView.tintColor = colorTheme.tintColor
    }
}

extension PHAssetEditingResultViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editingResults?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(PHAssetEditingResultCollectionViewCell.self)", for: indexPath) as! PHAssetEditingResultCollectionViewCell
        cell.setEditingResult(editingResults?[indexPath.item], at: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if initialTargetIndexPath == indexPath {
            initialTargetIndexPath = nil
            let cell = cell as! PHAssetEditingResultCollectionViewCell
            cell.setNeedsPlay()
        }
    }
}

extension PHAssetEditingResultViewController: UICollectionViewDelegate {
    
}

extension PHAssetEditingResultViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let centerOfCollection = view.convert(scrollView.center, to: scrollView)
        
        var nearestCell: PHAssetEditingResultCollectionViewCell?
        var distance: CGFloat = .greatestFiniteMagnitude
        
        for cell in collectionView.visibleCells {
            let cell = cell as! PHAssetEditingResultCollectionViewCell
            cell.assetView.stopAny()
            
            let currentDistance = cell.center.distance(to: centerOfCollection)
            if abs(currentDistance) < abs(distance) {
                distance = currentDistance
                
                nearestCell = cell
            }
        }
        
        nearestCell?.setNeedsPlay()
        nearestCell?.playIfNeeded()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}

private class PHAssetEditingResultCollectionViewCell: UICollectionViewCell {
    private var indexPath: IndexPath?
    private var editingResult: PHAssetResultable?
    
    fileprivate lazy var assetView: AssetView = {
        let assetView = AssetView(frame: .zero)
        assetView.contentMode = .scaleAspectFit
        return assetView
    }()
    
    private var needsPlay = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    internal func initialize() {
        contentView.addSubview(assetView)
        assetView.fitConstraints(to: contentView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        assetView.clearDrawing()
    }
    
    func setNeedsPlay() {
        needsPlay = true
    }
    
    func playIfNeeded() {
        if needsPlay {
            assetView.playAny()
        }
        needsPlay = false
    }
    
    func setEditingResult(_ editingResult: PHAssetResultable?, at indexPath: IndexPath) {
        self.indexPath = indexPath
        self.editingResult = editingResult
        
        DispatchQueue(label: #file + #function, qos: .utility).async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            if let resultItem = editingResult?.editingResultItems?.first, editingResult?.editingResultItems?.count == 1 {
                if resultItem.resourceType == .video {
                    let playerItem = AVPlayerItem(url: resultItem.url)
                    DispatchQueue.main.async { [weak self] in
                        guard self?.indexPath == indexPath else { return }
                        self?.assetView.videoView.isHidden = false
                        self?.assetView.playerItem = playerItem
                        self?.assetView.stopAny()
                        self?.playIfNeeded()
                    }
                }
                else if UTI(withURL: resultItem.url).conforms(to: .gif), let gifData = try? Data(contentsOf: resultItem.url) {
                    let image = UIImage(gifData: gifData)
                    DispatchQueue.main.async { [weak self] in
                        guard self?.indexPath == indexPath else { return }
                        self?.assetView.gifImage = image
                        self?.assetView.stopAny()
                        self?.playIfNeeded()
                    }
                }
                else {
                    let image = UIImage(contentsOfFile: resultItem.url.path)
                    DispatchQueue.main.async { [weak self] in
                        guard self?.indexPath == indexPath else { return }
                        self?.assetView.image = image
                    }
                }
            }
            else if editingResult?.editingResultItems?.isLivePhoto == true, let photoURL = editingResult?.editingResultItems?.item(for: .photo)?.url, let pairedVideoURL = editingResult?.editingResultItems?.item(for: .pairedVideo)?.url {
                self?.assetView.loadLivePhoto(from: photoURL, pairedVideoURL: pairedVideoURL, completion: { [weak self] (livePhoto) in
                    DispatchQueue.main.async { [weak self] in
                        guard self?.indexPath == indexPath else { return }
                        self?.assetView.livePhotoView.isHidden = false
                        self?.assetView.livePhoto = livePhoto
                        self?.assetView.stopAny()
                        self?.playIfNeeded()
                    }
                })
            }
        }
    }
}

private protocol PHAssetEditingResultCollectionLayoutDataSource {
    func appAssetInAssetEditingResultCollectionLayout(_ layout: PHAssetEditingResultCollectionLayout, at indexPath: IndexPath) -> AppAsset?
}

private class PHAssetEditingResultCollectionLayout: UICollectionViewLayout {
    private enum LayoutItem: String {
        case item = "Item"
        case header = "UICollectionElementKindSectionHeader"
        case footer = "UICollectionElementKindSectionFooter"
    }
    private var cache = [LayoutItem: [IndexPath: UICollectionViewLayoutAttributes]]()
    private func prepareCache() {
        cache.removeAll()
        
        cache[.item] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.header] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.footer] = [IndexPath: UICollectionViewLayoutAttributes]()
    }
    
    var dataSource: PHAssetEditingResultCollectionLayoutDataSource?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var minimumSpacing: CGFloat = 1
    private var _contentSize: CGSize = .zero
    
    public private(set) var paddingLeft: CGFloat = 0
    public private(set) var paddingRight: CGFloat = 0
    
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPositionX: CGFloat = 0
        _contentSize = .zero
        
        guard let collectionView = self.collectionView else { return }
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemSize = sizeForItem(at: indexPath)
            
            let itemPosition = CGPoint(x: itemPositionX, y: (collectionView.bounds.height - itemSize.height) / 2)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize)
            itemPositionX += itemSize.width + minimumSpacing
            
            cache[.item]?[indexPath] = attributes
            
            _contentSize.width = attributes.frame.maxX
            _contentSize.height = attributes.frame.height
            
            if indexPath.item == 0 {
                paddingLeft = (collectionView.bounds.width - itemSize.width) / 2
            }
            
            if indexPath.item == numberOfItems - 1 {
                paddingRight = (collectionView.bounds.width - itemSize.width) / 2
            }
        }
        
        cache[.item]?.forEach({ (indexPath, attributes) in
            attributes.frame.origin.x += paddingLeft
        })
        
        _contentSize.width += paddingLeft + paddingRight
    }
    
    private func estimatedSizeForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGSize {
        let coutentSize = CGSize(width: collectionView.bounds.width * 0.75, height: collectionView.bounds.height)
        guard let appAsset = self.dataSource?.appAssetInAssetEditingResultCollectionLayout(self, at: indexPath) else { return coutentSize }
        return appAsset.outputSize.aspectFit(in: coutentSize)
    }
    
    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let collectionView = self.collectionView else { return .zero }
        return estimatedSizeForItem(at: indexPath, in: collectionView)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.item]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache[.item]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.height != newBounds.height
    }
    
    var contentSize: CGSize {
        return CGSize(width: _contentSize.width - paddingLeft - paddingRight, height: _contentSize.height)
    }
    
    func estimatedContentSize(collectionView: UICollectionView) -> CGSize {
        var itemPositionX: CGFloat = 0
        var contentSize: CGSize = .zero
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemSize = estimatedSizeForItem(at: indexPath, in: collectionView)
            
            let itemPosition = CGPoint(x: itemPositionX, y: 0)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize)
            itemPositionX += itemSize.width + minimumSpacing
            
            contentSize.width = attributes.frame.maxX
            contentSize.height = attributes.frame.height
        }
        
        let paddingLeft = contentSize.width > collectionView.bounds.width ? minimumSpacing * 2 : (collectionView.bounds.width - contentSize.width) / 2
        let paddingRight = paddingLeft
        
        contentSize.width += paddingLeft + paddingRight
        
        return CGSize(width: contentSize.width - paddingLeft - paddingRight, height: contentSize.height)
    }
    
    override var collectionViewContentSize: CGSize {
        return _contentSize
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        var proposedRect = CGRect.zero
        proposedRect.origin = proposedContentOffset
        proposedRect.size = self.collectionView?.bounds.size ?? .zero
        
        let proposedCenterPoint = CGPoint(x: proposedRect.midX, y: proposedRect.midY)
        
        var offset: CGFloat = .greatestFiniteMagnitude
        for attributes in layoutAttributesForElements(in: proposedRect) ?? [] {
            let targetOffset = attributes.center.x - proposedCenterPoint.x
            if abs(targetOffset) < abs(offset) {
                offset = targetOffset
            }
        }
        
        return CGPoint(x: proposedContentOffset.x + offset, y: proposedContentOffset.y)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
}
