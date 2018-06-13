//
//  PhotoAlbumViewController.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 29..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos

private extension PHAssetCollectionSubtype {
    static let smartAlbumRecentlyDeleted = PHAssetCollectionSubtype(rawValue: 1000000201)
}

struct AlbumItemGroup {
    var items: [AlbumItem]
    var fetchResults: PHFetchResult<PHAssetCollection>?
    
    init(fetchResults: PHFetchResult<PHAssetCollection>?) {
        self.fetchResults = fetchResults
        var items = [AlbumItem]()

        fetchResults?.enumerateObjects { (collection, idx, stop) in
            //INFO: type of collection is "PHCollectionList" in very few cases - Hipstamatic's album
            //excluding PHCollectionList because -[PHCollectionList assetCollectionType]: unrecognized selector sent to instance 0x1d017b000
            if type(of: collection) == PHCollectionList.self{
                return
            }

            let albumItem = AlbumItem(collection: collection, assets: PHAsset.fetchAssets(in: collection, options: nil))
            items.append(albumItem)
        }

        self.items = items
    }
    
    init(items: [AlbumItem], fetchResults: PHFetchResult<PHAssetCollection>? = nil) {
        self.items = items
        self.fetchResults = fetchResults
    }
    
    mutating func updateAssets(_ assets: PHFetchResult<PHAsset>, at index: Int) {
        self.items[index].updateAssets(assets)
    }
}

struct AlbumItem {
    var fetchResults: PHFetchResult<PHAssetCollection>?
    var collection: PHAssetCollection?
    var assets: PHFetchResult<PHAsset>?
    
    init(fetchResults: PHFetchResult<PHAssetCollection>) {
        self.fetchResults = fetchResults
        self.collection = fetchResults.firstObject
        if let collection = self.collection {
            self.assets = PHAsset.fetchAssets(in: collection, options: nil)
        }
    }
    
    init(collection: PHAssetCollection, assets: PHFetchResult<PHAsset>) {
        self.collection = collection
        self.assets = assets
        self.fetchResults = nil
    }
    
    mutating func updateAssets(_ assets: PHFetchResult<PHAsset>) {
        self.assets = assets
    }
}

class PhotoAlbumViewController: UIViewController, PHPhotoLibraryChangeObserver  {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var dataSource: [AlbumItemGroup]?
    
    private var orderedSmartAlbumSubtypes: [PHAssetCollectionSubtype] = [
        PHAssetCollectionSubtype.smartAlbumUserLibrary,
        PHAssetCollectionSubtype.smartAlbumFavorites,
        PHAssetCollectionSubtype.smartAlbumVideos,
        PHAssetCollectionSubtype.smartAlbumSelfPortraits,
        PHAssetCollectionSubtype.smartAlbumLivePhotos,
        PHAssetCollectionSubtype.smartAlbumDepthEffect,
        PHAssetCollectionSubtype.smartAlbumPanoramas,
        PHAssetCollectionSubtype.smartAlbumTimelapses,
        PHAssetCollectionSubtype.smartAlbumSlomoVideos,
        PHAssetCollectionSubtype.smartAlbumBursts,
        PHAssetCollectionSubtype.smartAlbumScreenshots,
        PHAssetCollectionSubtype.smartAlbumAnimated,
        PHAssetCollectionSubtype.smartAlbumRecentlyDeleted
        ].compactMap { $0 }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        initialize()
    }
    
    private func initialize() {
        title = "Albums".localized
        
        //TODO: Preload
        PHPhotoLibraryManager.default.authorizeIfNeeded { authorized in
            guard authorized else { return }
            
            PHPhotoLibrary.shared().register(self)
            
            self.refetchCollections()
        }
    }
    
    private func refetchCollections() {
        let smartAlbums = self.orderedSmartAlbumSubtypes.compactMap { subtype -> AlbumItem? in
            let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
            return AlbumItem(fetchResults: collection)
        }
        
        let userCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)

        self.dataSource = [AlbumItemGroup(items: smartAlbums), AlbumItemGroup(fetchResults: userCollections as? PHFetchResult<PHAssetCollection>)]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset.left = 16
        collectionView.contentInset.right = 16
        
        collectionView.register(PhotoAlbumCollectionTitleView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoAlbumCollectionTitleView")
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.updateAlbumChanges(changeInstance)
        }
    }
    
    private var fetchResultAssetChanges: [(indexPath: IndexPath, changeDetails: PHFetchResultChangeDetails<PHAsset>)]?
    private var fetchResultCollectionChanges: [(section: Int, changeDetails: PHFetchResultChangeDetails<PHAssetCollection>)]?
    
    private func updateAlbumChanges(_ changeInstance: PHChange) {
        var assetChanges = [(indexPath: IndexPath, changeDetails: PHFetchResultChangeDetails<PHAsset>)]()
        var collectionChanges = [(section: Int, changeDetails: PHFetchResultChangeDetails<PHAssetCollection>)]()
        
        dataSource?.enumerated().forEach { sectionData in
            if let fetchResults = sectionData.element.fetchResults {
                if let changes = changeInstance.changeDetails(for: fetchResults) {
                    collectionChanges.append((section: sectionData.offset, changeDetails: changes))
                }
            }
            else {
                sectionData.element.items.enumerated().forEach { data in
                    guard let fetchResults = data.element.assets, let changes = changeInstance.changeDetails(for: fetchResults) else { return }
                    let indexPath = IndexPath(item: data.offset, section: sectionData.offset)
                    assetChanges.append((indexPath: indexPath, changeDetails: changes))
                }
            }
        }
        
        self.fetchResultAssetChanges = assetChanges
        self.fetchResultCollectionChanges = collectionChanges
        
        self.refetchCollections()
        self.updateCollectionViewChangesIfNeeded()
    }
    
    private func updateCollectionViewChangesIfNeeded() {
        self.collectionView?.performBatchUpdates({
            var removedIndexPaths = [IndexPath]()
            self.fetchResultCollectionChanges?.forEach { (section, changes) in
                if let removed = changes.removedIndexes, removed.count > 0 {
                    let indexPaths = removed.map { IndexPath(item: $0, section: section) }
                    self.collectionView.deleteItems(at: indexPaths)
                    
                    removedIndexPaths.append(contentsOf: indexPaths)
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    self.collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section: section) })
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    self.collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section: section) })
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: section), to: IndexPath(item: toIndex, section: section))
                }
            }
            
            let indexPathsToReload = self.fetchResultAssetChanges?.compactMap { (indexPath, changes) -> IndexPath? in
                if let removed = changes.removedIndexes, removed.count > 0 {
                    return indexPath
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    return indexPath
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    return indexPath
                }
                return nil
            }.filter { removedIndexPaths.contains($0) != true}
            
            if let indexPaths = indexPathsToReload {
                self.collectionView.reloadItems(at: indexPaths)
            }
            
        }) { _ in
            self.fetchResultAssetChanges = nil
            self.fetchResultCollectionChanges = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (navigationController as? AppDockNavigationController)?.setAppDockHidden(true, animated: animated)
        
        collectionView.visibleCells.forEach { $0.isHighlighted = false }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateCollectionViewChangesIfNeeded()
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?[section].items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        if let albumItem = dataSource?[safe: indexPath.section]?.items[indexPath.item] {
            cell.setAlbumItem(albumItem, at: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoAlbumCollectionTitleView", for: indexPath) as! PhotoAlbumCollectionTitleView
        if indexPath.section == 1 {
            view.title = "My Albums".localized
        }
        return view
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoPickerViewController = R.storyboard.appStoryboard.photoPickerViewController() else { return }
        
        let data = dataSource?[safe: indexPath.section]?.items[indexPath.item]
        photoPickerViewController.collection = data?.collection
        navigationController?.pushViewController(photoPickerViewController, animated: true)
        
        collectionView.cellForItem(at: indexPath)?.isHighlighted = true
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).width - 16) / 2
        return CGSize(width: width, height: width + 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 0 ? .zero : CGSize(width: collectionView.bounds.width, height: 30)
    }
}

internal class PhotoAlbumCollectionTitleView: UICollectionReusableView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        addSubview(titleLabel)
        titleLabel.fitConstraints(to: self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        title = nil
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var highlightedView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    private var indexPath: IndexPath?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        indexPath = nil
        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
    
    override var isHighlighted: Bool {
        didSet {
            highlightedView.isHidden = !isHighlighted
        }
    }
    
    func setAlbumItem(_ albumItem: AlbumItem, at indexPath: IndexPath) {
        self.indexPath = indexPath
        
        DispatchQueue.main.async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            let collection = albumItem.collection
            let assets = albumItem.assets
            self?.titleLabel.text = collection?.localizedTitle
            
            let largeNumber = assets?.count ?? 0
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            
            self?.subtitleLabel.text = numberFormatter.string(from: NSNumber(value:largeNumber))
            
            if collection?.assetCollectionSubtype != .smartAlbumRecentlyDeleted, let asset = assets?.lastObject {
                PHImageManager.default().requestImage(for: asset, targetSize: self?.imageView.bounds.size ?? .zero, contentMode: .aspectFit, options: nil, resultHandler: { (image, info) in
                    guard self?.indexPath == indexPath else { return }
                    self?.imageView.image = image
                })
            }
        }
    }
}
