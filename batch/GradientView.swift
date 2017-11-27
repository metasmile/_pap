//
// Created by BLACKGENE on 27/11/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable final class GradientView: UIView {

    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }

    override func draw(_ rect: CGRect) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.isOpaque = false
        gradient.frame = CGRect(x: CGFloat(0),
                y: CGFloat(0),
                width: self.frame.size.width,
                height: self.frame.size.height)
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.zPosition = -1
        layer.addSublayer(gradient)
    }

}
