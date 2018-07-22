//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{

    var collectionViewDefaultContentMode: PHImageContentMode {
        return traitCollection.userInterfaceIdiom == .phone ? .aspectFill : .aspectFit
    }

    func collectionViewDefaultImageSize(_ collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize {
        return self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).screenScaled()
    }

    func collectionViewDefaultCachingImageParam(_ collectionView: UICollectionView, at indexPath: IndexPath) -> PHCachingImageParam {
        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).screenScaled()
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .fast
        return PHCachingImageParam(targetSize: size, contentMode: collectionViewDefaultContentMode, options: requestOptions)
    }

    func collectionViewStartCachingImage(_ collectionView: UICollectionView, at indexPath: IndexPath) {
        if let asset = PHAssets.fetched.asset(at: indexPath){
            let p = self.collectionViewDefaultCachingImageParam(collectionView, at: indexPath)
            PhotosManager.default.cachingImageManager.startCachingImages(for: [asset], targetSize: p.targetSize, contentMode: p.contentMode, options: p.options)
        }
    }

    func collectionViewStopCachingImage(_ collectionView: UICollectionView, at indexPath: IndexPath) {
        if let asset = PHAssets.fetched.asset(at: indexPath){
            let p = self.collectionViewDefaultCachingImageParam(collectionView, at: indexPath)
            PhotosManager.default.cachingImageManager.stopCachingImages(for: [asset], targetSize: p.targetSize, contentMode: p.contentMode, options: p.options)
        }
    }
}