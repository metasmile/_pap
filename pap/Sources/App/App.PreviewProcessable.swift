//
//  App.PreviewProcessable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public protocol PreviewProcessableApp: App {
    //INFO: prevent memory leak for creating CIImage(uiImage:)
    var previewOriginalImageCache: NSCache<NSString, CIImage>? { get set }
    func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void))
    
    //TODO: usage levels?
    func showsVisibleEffectWhileProcessing() -> Bool
}

extension PreviewProcessableApp {
    public var previewOriginalImageCache: NSCache<NSString, CIImage>? { get { return nil } set {} }
    public func showsVisibleEffectWhileProcessing() -> Bool {
        return false
    }
}
