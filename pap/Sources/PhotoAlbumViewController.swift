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

class PhotoAlbumViewController: UIViewController, PHPhotoLibraryChangeObserver  {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var dataSource: [[(collection: PHAssetCollection, assets: PHFetchResult<PHAsset>)]]?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Albums".localized
        
        collectionView.contentInset.left = 16
        collectionView.contentInset.right = 16
        
        collectionView.register(PhotoAlbumCollectionTitleView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoAlbumCollectionTitleView")
        
        PHPhotoLibraryManager.default.authorizeIfNeeded { authorized in
            guard authorized else { return }
            
            PHPhotoLibrary.shared().register(self)
            
            let smartAlbums = self.orderedSmartAlbumSubtypes.compactMap { subtype -> (collection: PHAssetCollection, assets: PHFetchResult<PHAsset>)? in
                guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil).firstObject else { return nil }
                return (collection: collection, assets: PHAsset.fetchAssets(in: collection, options: nil))
            }
            
            let userCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
            let userAlbums = userCollections.objects(at: IndexSet(integersIn: 0..<userCollections.count)).compactMap { collection -> (collection: PHAssetCollection, assets: PHFetchResult<PHAsset>)? in
                guard let collection = collection as? PHAssetCollection else { return nil }
                return (collection: collection, assets: PHAsset.fetchAssets(in: collection, options: nil))
            }
            
            self.dataSource = [smartAlbums, userAlbums]
            self.collectionView.reloadData()
        }
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.updateAlbumChanges(changeInstance)
        }
    }
    
    private func updateAlbumChanges(_ changeInstance: PHChange) {
        var fetchResultChanges = [(indexPath: IndexPath, changeDetails: PHFetchResultChangeDetails<PHAsset>)]()
        dataSource?.enumerated().forEach { sectionData in
            sectionData.element.enumerated().forEach { data in
                guard let changes = changeInstance.changeDetails(for: data.element.assets) else { return }
                let indexPath = IndexPath(item: data.offset, section: sectionData.offset)
                fetchResultChanges.append((indexPath: indexPath, changeDetails: changes))
            }
        }
        
        guard fetchResultChanges.isEmpty == false else { return }
        
        self.collectionView.performBatchUpdates({
            fetchResultChanges.forEach { (indexPath, changes) in
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
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (navigationController as? AppDockNavigationController)?.setAppDockHidden(true, animated: animated)
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?[section].count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        if let data = dataSource?[safe: indexPath.section]?[indexPath.item] {
            cell.setCollection(data.collection, at: indexPath)
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
        
        let cell = collectionView.cellForItem(at: indexPath) as? PhotoAlbumCollectionViewCell
        cell?.isHighlighted = true
        let data = dataSource?[safe: indexPath.section]?[indexPath.item]
        photoPickerViewController.collection = data?.collection
        navigationController?.pushViewController(photoPickerViewController, animated: true)
        
        cell?.isHighlighted = false
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
    
    func setCollection(_ collection: PHAssetCollection, at indexPath: IndexPath) {
        self.indexPath = indexPath
        
        DispatchQueue.main.async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
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
