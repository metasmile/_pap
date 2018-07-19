//
//  App.Previewable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

//TODO: PreviewableApp
public protocol PreviewableApp: App {
    var defaultEditStateValue: ImageEditStateValue? { get }
    func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?)
    func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in dockContent: AppDockContent?)
}

extension PreviewableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {}
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in dockContent: AppDockContent?) {}
}

public protocol PreviewableStatableApp {

}

public protocol PreviewProcessableApp: App {
    func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void))
}
