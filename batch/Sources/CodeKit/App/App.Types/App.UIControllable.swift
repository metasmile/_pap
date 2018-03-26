//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol UIControllableApp: App {
    var controlView:UIView? { get }
}

extension UIControllableApp{
    public var controlView: UIView? {
        let view = UIStackView(frame: .zero)
        view.alignment = .fill
        view.distribution = .equalCentering
        view.axis = .horizontal

        let label = UILabel()
        label.text = type(of: self).info.displayName + " Control View Area"
        label.textAlignment = .center
        label.sizeToFit()
        view.addArrangedSubview(label)

        return view
    }
}