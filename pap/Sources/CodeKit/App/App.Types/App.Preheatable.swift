//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol PreheatingFinishAction: Codable{}

extension String: PreheatingFinishAction{}
extension Int: PreheatingFinishAction{}

public protocol PreheatableApp: App{
    func performPreheating(item:AppAsset, _ async:AsyncSignal) -> PreheatingFinishAction?
}
