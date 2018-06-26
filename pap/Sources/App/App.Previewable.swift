//
//  App.Previewable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public protocol PreviewableApp: App {
    var currentEditStateValue: ImageEditStateValue? { get }
    var previewAsynchronously: Bool { get }
    func previewAsync(_ appAsset: AppAsset, at indexPath: IndexPath, completion: @escaping ((UIImage?) -> Void))
}

public protocol PreviewCachableApp: App {
    func removeAllCachedPreviewImages()
    func cachedPreviewImage(_ appAsset: AppAsset, at indexPath: IndexPath) -> UIImage?
}

extension PreviewableApp {
    public var currentEditStateValue: ImageEditStateValue? { return nil }
    public var previewAsynchronously: Bool { return false }
    public func previewAsync(_ appAsset: AppAsset, at indexPath: IndexPath, completion: @escaping ((UIImage?) -> Void)) {}
}

extension PreviewCachableApp {
    public func removeAllCachedPreviewImages() {}
    public func cachedPreviewImage(_ appAsset: AppAsset, at indexPath: IndexPath) -> UIImage? { return nil }
}
