//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

// AppDockContentPreferable
public protocol AppDockContentPreferable {
    var height: CGFloat {get}
    var pinned:Bool {get}
}

public struct AppDockContentPreferences: AppDockContentPreferable {
    public var height: CGFloat
    public var pinned: Bool = false

    init(){
        self.height = 44
    }

    init(height:CGFloat){
        self.height = height
    }
}

// AppDockContent
public protocol AppDockContentDescribable {
    var view: UIView {get}
    var preferences: AppDockContentPreferable? {get}
}
public struct AppDockContent: AppDockContentDescribable {
    public var view: UIView
    public var preferences: AppDockContentPreferable? = nil
}

// AppDockReloadableContentView
protocol AppDockContentView: class{
    func reloadContent()
    func reloadContentThatFits(size:CGSize)
}

// AppDockReloadableContentView default behavior
extension AppDockContentView where Self:UIView{
    func reloadContent() {
        layoutIfNeeded()
    }
    func reloadContentThatFits(size: CGSize) {
        layoutIfNeeded()
    }
}