//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public final class BatchAppCenter{
    public static let shared = BatchAppCenter()

    public var current:Appable.Type = TransformApp.self
}
