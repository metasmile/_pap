//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

private struct PhotoPickerViewControllerPHCachingImageDefault {
    static let RequestOption = { () -> PHImageRequestOptions in
        var option = PHImageRequestOptions()
        option.resizeMode = .fast
        option.version = .current
        return option
    }()
}

extension PhotoPickerViewController{

    var collectionViewDefaultContentMode: PHImageContentMode {
        return traitCollection.userInterfaceIdiom == .phone ? .aspectFill : .aspectFit
    }

    func collectionViewDefaultImageSize(_ collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize {
        return preferredPhotoPickerCollectionItemSize.screenScaled()
    }

    func collectionViewDefaultCachingCellImageRequestOption(_ collectionView: UICollectionView, at indexPath: IndexPath) -> PHAssetRequestOption {
        return (
                targetSize: preferredPhotoPickerCollectionItemSize.screenScaled()
                , contentMode: collectionViewDefaultContentMode
                , options: PhotoPickerViewControllerPHCachingImageDefault.RequestOption
        )
    }

    func collectionViewCurrentAllCachingImageRequestOptions(_ collectionView: UICollectionView, at indexPath: IndexPath) -> [PHAssetRequestOption] {
        var neededCachingOptions = [collectionViewDefaultCachingCellImageRequestOption(collectionView, at: indexPath)]
        neededCachingOptions += AppCenter.default.currentInstanceAs(PHAssetCacheableApp.self)?.needsCachingRequestOptions ?? []
        return neededCachingOptions
    }

    func collectionViewStartCachingImages(_ collectionView: UICollectionView, at indexPaths: [IndexPath]) {
        _collectionViewCachingImages(register: true, collectionView, at: indexPaths)
    }

    func collectionViewStopCachingImages(_ collectionView: UICollectionView, at indexPaths: [IndexPath]) {
        _collectionViewCachingImages(register: false, collectionView, at: indexPaths)
    }

    private func _collectionViewCachingImages(register:Bool, _ collectionView: UICollectionView, at indexPaths: [IndexPath]) {
        guard let indexPaths = indexPaths.nilEmpty else {
            return
        }

        let assets = indexPaths.compactMap { PHAssets.fetched.asset(at: $0) }
        for option in collectionViewCurrentAllCachingImageRequestOptions(collectionView, at:indexPaths[0]){
            if register {
                PhotosManager.default.cachingImageManager.startCachingImages(for: assets, targetSize: option.targetSize, contentMode: option.contentMode, options: option.options)
            }else{
                PhotosManager.default.cachingImageManager.stopCachingImages(for: assets, targetSize: option.targetSize, contentMode: option.contentMode, options: option.options)
            }
        }
    }
}
