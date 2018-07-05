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
}

extension PreviewableApp {
    public var currentEditStateValue: ImageEditStateValue? { return nil }
}

public protocol PreviewProcessableApp: App {
    func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((UIImage?) -> Void))
}
