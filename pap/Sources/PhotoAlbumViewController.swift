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
    
    mutating func updateAssets(_ assets: PHFetchResult<PHAsset>, at index: Int) {
        self.items[index].updateAssets(assets)
    }
}

struct AlbumItem {
    var collection: PHAssetCollection
    var assets: PHFetchResult<PHAsset>
    
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
        //TODO: Preload
        PHPhotoLibraryManager.default.authorizeIfNeeded { authorized in
            guard authorized else { return }
            
            PHPhotoLibrary.shared().register(self)
            
            let smartAlbums = self.orderedSmartAlbumSubtypes.compactMap { subtype -> AlbumItem? in
                guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil).firstObject else { return nil }
                return AlbumItem(collection: collection, assets: PHAsset.fetchAssets(in: collection, options: nil))
            }
            
            let userCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
            let userAlbums = userCollections.objects(at: IndexSet(integersIn: 0..<userCollections.count)).compactMap { collection -> AlbumItem? in
                guard let collection = collection as? PHAssetCollection else { return nil }
                return AlbumItem(collection: collection, assets: PHAsset.fetchAssets(in: collection, options: nil))
            }
            
            self.dataSource = [AlbumItemGroup(items: smartAlbums), AlbumItemGroup(items: userAlbums)]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Albums".localized
        
        collectionView.contentInset.left = 16
        collectionView.contentInset.right = 16
        
        collectionView.register(PhotoAlbumCollectionTitleView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoAlbumCollectionTitleView")
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.updateAlbumChanges(changeInstance)
        }
    }
    
    private var fetchResultChanges: [(indexPath: IndexPath, changeDetails: PHFetchResultChangeDetails<PHAsset>)]?
    private func updateAlbumChanges(_ changeInstance: PHChange) {
        var fetchResultChanges = [(indexPath: IndexPath, changeDetails: PHFetchResultChangeDetails<PHAsset>)]()
        dataSource?.enumerated().forEach { sectionData in
            sectionData.element.items.enumerated().forEach { data in
                guard let changes = changeInstance.changeDetails(for: data.element.assets) else { return }
                let indexPath = IndexPath(item: data.offset, section: sectionData.offset)
                fetchResultChanges.append((indexPath: indexPath, changeDetails: changes))
            }
        }
        
        guard fetchResultChanges.isEmpty == false else { return }
        self.fetchResultChanges = fetchResultChanges
        
        self.updateCollectionViewChangesIfNeeded()
    }
    
    private func updateCollectionViewChangesIfNeeded() {
        self.collectionView?.performBatchUpdates({
            self.fetchResultChanges?.forEach { (indexPath, changes) in
                self.dataSource?[indexPath.section].updateAssets(changes.fetchResultAfterChanges, at: indexPath.item)
                
                if let removed = changes.removedIndexes, removed.count > 0 {
                    self.collectionView.reloadItems(at: [indexPath])
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    self.collectionView.reloadItems(at: [indexPath])
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    self.collectionView.reloadItems(at: [indexPath])
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    self.collectionView.reloadItems(at: [indexPath])
                }
            }
        }) { _ in
            self.fetchResultChanges = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (navigationController as? AppDockNavigationController)?.setAppDockHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateCollectionViewChangesIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        collectionView.visibleCells.forEach { $0.isHighlighted = false }
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
            self?.titleLabel.text = collection.localizedTitle
            
            let largeNumber = assets.count
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            
            self?.subtitleLabel.text = numberFormatter.string(from: NSNumber(value:largeNumber))
            
            if collection.assetCollectionSubtype != .smartAlbumRecentlyDeleted, let asset = assets.lastObject {
                PHImageManager.default().requestImage(for: asset, targetSize: self?.imageView.bounds.size ?? .zero, contentMode: .aspectFit, options: nil, resultHandler: { (image, info) in
                    guard self?.indexPath == indexPath else { return }
                    self?.imageView.image = image
                })
            }
        }
    }
}
