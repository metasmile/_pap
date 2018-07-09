//
//  App.Previewable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public protocol PreviewableApp: App {
    var defaultEditStateValue: ImageEditStateValue? { get }
    func setSelectedEditStateValue(_ editStateValue: ImageEditStateValue)
}

extension PreviewableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setSelectedEditStateValue(_ editStateValue: ImageEditStateValue) {}
}

public protocol PreviewProcessableApp: App {
    func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void))
}
