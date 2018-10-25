//
//  RoundedButton.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 8. 10..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    @IBInspectable
    var cornerRadius: CGFloat = 6 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = true
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
}
