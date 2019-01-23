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
        
        var numberOfImages = 0
        var numberOfVideos = 0
        for asset in targetResultAssets.map({ $0.asset }) {
            if asset.mediaType == .image {
                numberOfImages += 1
            }
            else if asset.mediaType == .video {
                numberOfVideos += 1
            }
        }
        
        let numberOfItems = PHAsset.formattedNumberString(numberOfImages: numberOfImages, numberOfVideos: numberOfVideos).localizedLowercase
        
        var excludedActions = excludedActions
        
        //INFO: can not export live photo
        if targetResultAssets.contains(where: { $0.editingResultItems?.isLivePhoto == true }) {
            excludedActions.append(.share)
        }
        
//        let vc = PHAssetEditingResultViewController()
//        let nc = UINavigationController(rootViewController: vc)
//        
//        vc.editingResults = targetResultAssets
//        vc.didDismissHandler = {
//            asyncSignal.end()
//        }
//        
//        asyncSignal.begin()
//        
//        DispatchQueue.main.async{
//            UIViewController.present(nc, animated: true)
//        }
//        
//        asyncSignal.waitUntilEnd()
//        
//        return

        let alert = UIAlertController.actionSheet(title: "Choose an export option for %@".localizedFormatted(numberOfItems), message: nil)
        if !excludedActions.contains(.create) {
            alert.addAction(UIAlertAction(title: "Save".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.share) {
            alert.addAction(UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.modify) {
            alert.addAction(UIAlertAction(title: "Modify".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.modifyingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.share) && !excludedActions.contains(.create) {
            alert.addAction(UIAlertAction(title: "Save and Share".localized, style: .default, handler: { action in
                actionQueue.async{
                    let assets = self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    self.sharingAndWait(from: assets.map({ $0.localIdentifier }), actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
            asyncSignal.end()
        }))

        asyncSignal.begin()

        DispatchQueue.main.async{
            UIViewController.present(alert, animated: true)
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

class PHAssetEditingResultViewController: UIViewController {
    // preview collection view (with urls)
    // export options
    // - create
    // - modify
    // - share
    
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PHAssetEditingResultCollectionViewCell.self, forCellWithReuseIdentifier: "\(PHAssetEditingResultCollectionViewCell.self)")
        return collectionView
    }()
    
    var editingResults:[PHAssetResultable]?
    var didDismissHandler: (() -> Void)?
}

extension PHAssetEditingResultViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerThemeable()
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelButtonDidTap))
        navigationItem.setLeftBarButton(cancelButton, animated: true)
    }
    
    @objc private func cancelButtonDidTap(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: self.didDismissHandler)
    }
}

extension PHAssetEditingResultViewController: AppColorThemeable {
    func applyTheme(_ colorTheme: AppColorTheme) {
        
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
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PHAssetEditingResultCollectionViewCell
        cell.assetView.clearDrawing()
    }
}

extension PHAssetEditingResultViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PHAssetEditingResultCollectionViewCell
        cell.assetView.isPlaying ? cell.assetView.pauseAny() : cell.assetView.playAny()
    }
}

extension PHAssetEditingResultViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width * 0.75, height: collectionView.bounds.height)
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
    
    func setEditingResult(_ editingResult: PHAssetResultable?, at indexPath: IndexPath) {
        self.indexPath = indexPath
        self.editingResult = editingResult
        
        if let resultItem = editingResult?.editingResultItems?.first, editingResult?.editingResultItems?.count == 1 {
            if resultItem.resourceType == .video {
                assetView.videoView.isHidden = false
                assetView.playerItem = AVPlayerItem(url: resultItem.url)
//                assetView.playAny()
            }
            else if UTI(withURL: resultItem.url).conforms(to: .gif), let gifData = try? Data(contentsOf: resultItem.url) {
                assetView.gifImage = UIImage(gifData: gifData)
            }
            else {
                assetView.image = UIImage(contentsOfFile: resultItem.url.path)
            }
        }
        else if editingResult?.editingResultItems?.isLivePhoto == true, let photoURL = editingResult?.editingResultItems?.item(for: .photo)?.url, let pairedVideoURL = editingResult?.editingResultItems?.item(for: .pairedVideo)?.url {
            assetView.loadLivePhoto(from: photoURL, pairedVideoURL: pairedVideoURL, completion: { [weak self] (livePhoto) in
                guard self?.indexPath == indexPath else { return }
                self?.assetView.livePhotoView.isHidden = false
                self?.assetView.livePhoto = livePhoto
//                self?.assetView.playAny()
            })
        }
    }
}
