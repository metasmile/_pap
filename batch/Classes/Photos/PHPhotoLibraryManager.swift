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

    public func authorizeIfNeeded(_ completion:((Bool) -> ())?=nil) {
        //photos access authorization
        PHPhotoLibraryManager.default.requestPhotoLibraryAuthorizationIfNeeded { [unowned self] (authorized) in
            if authorized{
                PHPhotoLibrary.shared().register(self)
            }
            completion?(authorized)
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        self.changes = changeInstance
    }

    private func requestPhotoLibraryAuthorizationIfNeeded(_ completion: @escaping ((Bool) -> ())) {
        let status = PHPhotoLibrary.authorizationStatus()

        DispatchQueue.main.async {
            switch status {
            case .authorized:
                completion(true)
                break
            case .notDetermined:
                self.requestPhotoLibraryAuthorization(completion)
            case .denied, .restricted:
                self.showPhotoLibrarySettingsAlert()
                completion(false)
            }
        }
    }

    private func requestPhotoLibraryAuthorization(_ completion: @escaping ((Bool) -> ())) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async { completion(true) }
            case .notDetermined, .denied, .restricted:
                DispatchQueue.main.async {
                    self.showPhotoLibrarySettingsAlert()
                    completion(false)
                }
            }
        }
    }

    private func showPhotoLibrarySettingsAlert() {
        let alert = UIAlertController(title: "Photos Access Disabled".localized, message: "Please open settings and allow access to your photos".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings".localized, style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}