//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ConverterAppDefaults: AppDefaults{
    var convertingDirection: ConvertableDirection {get set}
}

extension Defaults: ConverterAppDefaults {
    var convertingDirection: ConvertableDirection {
        set { set(newValue) }
        get { return get(or:ConvertableDirection(from: .video, to: .livephoto)) }
    }
}

enum ConvertableMediaType: Int, Decodable{
    case any
    case video
    case livephoto
    case gif
    case burst
    case timelapse
}

struct ConvertableDirection: Codable, Equatable {
    var from:ConvertableMediaType
    var to:ConvertableMediaType

    private enum CodingKeys: Int, CodingKey {
        case from
        case to
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from.rawValue, forKey: .from)
        try container.encode(to.rawValue, forKey: .to)
    }

    public static func == (lhs: ConvertableDirection, rhs: ConvertableDirection) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}