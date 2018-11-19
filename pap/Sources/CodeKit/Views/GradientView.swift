//
// Created by BLACKGENE on 27/11/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit

@IBDesignable final class GradientView: UIView {
    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        (layer as! CAGradientLayer).colors = [startColor.cgColor, endColor.cgColor]
    }
}
