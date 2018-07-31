//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol PreheatingFinishAction: Codable{}

extension String: PreheatingFinishAction{}
extension Int: PreheatingFinishAction{}

public protocol PreheatableApp: App{
    func performPreheating(item: PHAssetParamable,  _ async: AsyncWaitSignalable)  -> PreheatingFinishAction?

    //INFO: It will be called at once when definitely cancel.
    func didCancelPreheating()

    //INFO:
    // It will be called when finish current perform cycle (for grouped-enqueuing items).
    // It means that it related with times of calling "performPrefetchIfNeeded". So it can be called N times.
    func didFinishCurrentPreheatingCycle()
}

extension PreheatableApp{
    public func didCancelPreheating(){}
    public func didFinishCurrentPreheatingCycle(){}
}
