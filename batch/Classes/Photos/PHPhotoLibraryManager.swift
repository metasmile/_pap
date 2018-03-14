//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

final class PHPhotoLibraryManager: NSObject {
    static let `default` = PHPhotoLibraryManager()
    static let cachingImageManager = PHCachingImageManager()
}

extension PHPhotoLibraryManager {
    public func requestPhotoLibraryAuthorizationIfNeeded(_ completion: @escaping ((Bool) -> ())) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
            break
        case .notDetermined:
            DispatchQueue.main.async {
                self.requestPhotoLibraryAuthorization(completion)
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPhotoLibrarySettingsAlert()
                completion(false)
            }
        }
    }

    public func requestPhotoLibraryAuthorization(_ completion: @escaping ((Bool) -> ())) {
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