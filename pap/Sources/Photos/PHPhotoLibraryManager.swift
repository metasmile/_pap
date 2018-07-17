//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

final class PHPhotoLibraryManager: NSObject, KeyPathWatchable, PHPhotoLibraryChangeObserver {
    static let `default` = PHPhotoLibraryManager()
    static let cachingImageManager = PHCachingImageManager()

    @objc dynamic
    public private(set) var changes:PHChange?

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
                    self._authorizeIfNeeded(status == .notDetermined ? .restricted : status, completion)
                }
            }
            return
        }

        self.showPhotoLibrarySettingsAlert()
        completion(false)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        self.changes = changeInstance
    }

    private func showPhotoLibrarySettingsAlert() {
        let alert = UIAlertController(title: "Photos Access Disabled".localized, message: "Please open settings and allow access to your photos".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings".localized, style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        UIViewController.root?.present(alert, animated: true, completion: nil)
    }
}