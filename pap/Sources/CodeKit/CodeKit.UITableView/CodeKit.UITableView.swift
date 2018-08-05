//
// Created by BLACKGENE on 8/2/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
extension UITableView{

    class func createHeaderFooterTextView(text:String, fontSize:CGFloat, fontColor:UIColor, inset:UIEdgeInsets) -> UITextView{
        let label = UITextView()
        label.autoresizingMask = [.flexibleWidth]
        label.backgroundColor = UIColor.clear
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.text = text
        label.isEditable = false
        label.textColor = fontColor
        label.isUserInteractionEnabled = false
        label.textContainer.lineBreakMode = .byWordWrapping
        label.textContainer.maximumNumberOfLines = Int.max
        label.textContainerInset = inset
        label.sizeToFit()
        label.scrollsToTop = true
        return label
    }

    class func createHeaderFooterViewForMessage(text:String) -> UITextView{
        return self.createHeaderFooterTextView(
                text: text
                , fontSize: UIFont.smallSystemFontSize
                , fontColor: UIColor.lightGray
                , inset: UIEdgeInsetsMake(10, 15, 20, 10)
        )
    }
}