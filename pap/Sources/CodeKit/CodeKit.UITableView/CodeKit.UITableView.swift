//
// Created by BLACKGENE on 8/2/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

//wtf uikit
private class _UITextView: UITextView{
    override func layoutSubviews() {
        setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        super.layoutSubviews()
    }
}

extension UITableView{

    private class func createHeaderFooterTextView(text:String, fontSize:CGFloat=UIFont.systemFontSize, fontColor:UIColor=UIColor.gray, inset:UIEdgeInsets=UIEdgeInsetsMake(10, 10, 10, 10)) -> UITextView{
        let textView = _UITextView()
        textView.autoresizingMask = [.flexibleWidth]
        textView.backgroundColor = UIColor.clear
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.systemFont(ofSize: fontSize)
        textView.isEditable = false
        textView.textColor = fontColor
        textView.isUserInteractionEnabled = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainerInset = inset
        textView.textContainer.heightTracksTextView = true
        textView.text = text
        textView.sizeToFit()
        return textView
    }

    class func createHeaderFooterViewForSmallMessage(text:String) -> UITextView{
        return self.createHeaderFooterTextView(
                text: text
                , fontSize: UIFont.smallSystemFontSize
                , fontColor: UIColor.gray
                , inset: UIEdgeInsetsMake(10, 10, 15, 20)
        )
    }
}