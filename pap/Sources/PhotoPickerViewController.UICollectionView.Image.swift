//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

private struct PHCachingImages {
    static let defaultRequestOptions = { () -> PHImageRequestOptions in
        var option = PHImageRequestOptions()
        option.resizeMode = .fast
        return option
    }()
}

extension PhotoPickerViewController{

    var collectionViewDefaultContentMode: PHImageContentMode {
        return traitCollection.userInterfaceIdiom == .phone ? .aspectFill : .aspectFit
    }

    func collectionViewDefaultImageSize(_ collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize {
        return self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).screenScaled()
    }

    func collectionViewDefaultCachingImageRequest(_ collectionView: UICollectionView, at indexPath: IndexPath) -> PHImageManagerRequest {
        return (
                targetSize: self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).screenScaled()
                , contentMode: collectionViewDefaultContentMode
                , options: PHCachingImages.defaultRequestOptions
        )
    }

    func collectionViewStartCachingImages(_ collectionView: UICollectionView, at indexPaths: [IndexPath]) {
        if let indexPaths = indexPaths.nilEmpty{
            let p = self.collectionViewDefaultCachingImageRequest(collectionView, at: indexPaths[0])
            PhotosManager.default.cachingImageManager.startCachingImages(for: indexPaths.compactMap { PHAssets.fetched.asset(at: $0) }, targetSize: p.targetSize, contentMode: p.contentMode, options: p.options)
        }
    }

    func collectionViewStopCachingImages(_ collectionView: UICollectionView, at indexPaths: [IndexPath]) {
        if let indexPaths = indexPaths.nilEmpty{
            let p = self.collectionViewDefaultCachingImageRequest(collectionView, at: indexPaths[0])
            PhotosManager.default.cachingImageManager.stopCachingImages(for: indexPaths.compactMap { PHAssets.fetched.asset(at: $0) }, targetSize: p.targetSize, contentMode: p.contentMode, options: p.options)
        }
    }
}