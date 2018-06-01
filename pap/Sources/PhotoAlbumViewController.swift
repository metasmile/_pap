//
//  PhotoAlbumViewController.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 29..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoAlbumViewController: UIViewController  {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var dataSource: [[PHAssetCollection]]?
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
        PHAssetCollectionSubtype(rawValue: 1000000201)//최근 삭제된 사진
        ].compactMap { $0 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let smartAlbums = orderedSmartAlbumSubtypes.compactMap {
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: $0, options: nil).firstObject
        }
        
        let userCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        let userAlbums = userCollections.objects(at: IndexSet(integersIn: 0..<userCollections.count)).compactMap { $0 as? PHAssetCollection }
        
        dataSource = [smartAlbums, userAlbums].compactMap { $0 }
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
        let collection = dataSource?[safe: indexPath.section]?[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        cell.titleLabel.text = collection?.localizedTitle
        return cell
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoPickerViewController = R.storyboard.appStoryboard.photoPickerViewController() else { return }
        let collection = dataSource?[safe: indexPath.section]?[indexPath.item]
        photoPickerViewController.collection = collection
        navigationController?.pushViewController(photoPickerViewController, animated: true)
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width / 2, height: collectionView.bounds.width / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
}
