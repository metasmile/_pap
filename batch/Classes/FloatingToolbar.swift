//
//  FloatingToolbar.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 17..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

class FloatingToolbar: FloatingContentView {
    @IBOutlet weak var toolbar: UIToolbar!
    
    var toolbarItems: [UIBarButtonItem]? {
        didSet {
            toolbar.items = toolbarItems
        }
    }
}

extension UIBarButtonItem {
    convenience init(title: String, style: UIBarButtonItemStyle, target: Any?, action: Selector, height: CGFloat) {
        let button = UIButton(type: .system)
        
        let fontSize: CGFloat = 17
        
        button.setAttributedTitle(NSAttributedString(string: title, attributes: [NSFontAttributeName: style == .done ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize) ]), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        
        button.sizeToFit()
        button.frame.size.height = height
        
        self.init(customView: button)
    }
}
