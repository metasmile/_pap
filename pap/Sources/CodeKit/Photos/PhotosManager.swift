//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

final class PhotosManager: NSObject, PropertyWatchable, PHPhotoLibraryChangeObserver {
    static let `default` = PhotosManager()

/*
    PHCachingImageManager
*/
    let cachingImageManager = { () -> PHCachingImageManager in
#if DEBUG
        return _PHCachingImageManager_Debug()
#else
        return PHCachingImageManager()
#endif
    }()


/*
    Authorization
*/
    public func authorizeIfNeeded(_ completion:@escaping (Bool) -> ()) {
        _authorizeIfNeeded(PHPhotoLibrary.authorizationStatus(), completion)
    }

    private func _authorizeIfNeeded(_ status:PHAuthorizationStatus, _ completion:@escaping (Bool) -> ()) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)

        if status == .authorized{
            PHPhotoLibrary.shared().register(self)
            completion(true)
            return
        }

        if status == .notDetermined{
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async{
                    assert(status != .notDetermined,"what?")
                    self._authorizeIfNeeded(status == .notDetermined ? .restricted : status, completion)
                }
            }
            return
        }

        self.showPhotoLibrarySettingsAlert()
        completion(false)
    }

    private func showPhotoLibrarySettingsAlert() {
        let alert = UIAlertController(title: "Photos Access Disabled".localized, message: "Please open settings and allow access to your photos".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings".localized, style: .default, handler: { (action) in
            UIApplication.shared.openSettings()
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        UIViewController.present(alert, animated: true, completion: nil)
    }

/*
    PHChange
*/
    @objc dynamic
    public private(set) var changes:PHChange?

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        self.changes = changeInstance
    }
}


/*
PHCachingImageManager
*/

private class _PHCachingImageManager_Debug: PHCachingImageManager {

    private var targetSizesByAsset = [String:Set<CGSize>]()
    private func registerTargetSize(by assets:[PHAsset]?, targetSize:CGSize?){
        assert(DispatchQueue.main.label == DispatchQueue.currentLabel, "It tried to access PHCachingImageManager in not mainqueue.")

        guard let assets = assets else {
            targetSizesByAsset.removeAll()
            return
        }

        for asset in assets{
            if let size = targetSize, size != CGSize.zero{
                var mSizeSet:Set<CGSize> = targetSizesByAsset[asset.localIdentifier] ?? Set<CGSize>()
                if mSizeSet.contains(size){
                    continue
                }

                if mSizeSet.count>0{
                    print("[i] INFO: New caching image size \(String(describing: size)) is being newly added into -> \(String(describing: mSizeSet)) ")
                }

                mSizeSet.insert(size)
                targetSizesByAsset[asset.localIdentifier] = mSizeSet
            }else{
                targetSizesByAsset[asset.localIdentifier] = nil
            }
        }
    }

    override func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        if let sizeSet = targetSizesByAsset[asset.localIdentifier], sizeSet.count>0, sizeSet.contains(targetSize) == false{
            print("[i] INFO: New caching image size \(String(describing: targetSize)) is being newly added into -> \(String(describing: sizeSet)) ")
        }
        return super.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: resultHandler)
    }

    override func startCachingImages(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        registerTargetSize(by: assets, targetSize: targetSize)
        super.startCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }

    override func stopCachingImages(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        registerTargetSize(by: assets, targetSize: nil)
        super.stopCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }

    override func stopCachingImagesForAllAssets() {
        registerTargetSize(by: nil, targetSize: nil)
        super.stopCachingImagesForAllAssets()
    }
}
