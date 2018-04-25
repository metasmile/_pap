//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

// AppDock
public protocol AppDock {
    func expandDockIfNeeded(reloadContents:Bool?) // nil means it should act with default behavior
    func contractDockIfNeeded(reloadContents:Bool?)
}

public protocol AppDockDelegate {
    func dockWillExpand(_ dock:AppDock)
    func dockDidExpand(_ dock:AppDock)

    func dockWillContract(_ dock:AppDock)
    func dockDidContract(_ dock:AppDock)
}

// AppDockContentPreferable
public protocol AppDockContentPreferable {
    var minimumHeight: CGFloat {get}
    var pinned:Bool {get}
    //TODO: allow/disallow drawer open, or add something more detailed rules for accessory view.
}

public struct AppDockContentPreferences: AppDockContentPreferable {
    public var minimumHeight: CGFloat = 0
    public var pinned: Bool = false

    init(){}

    init(height:CGFloat){
        self.minimumHeight = height
    }
}

// AppDockContent
public protocol AppDockContent {
    var view: UIView {get}
    var preferences: AppDockContentPreferable? {get}
    var delegate: AppDockDelegate? {get}

    func willSetContentView(_ view:UIView, dock:AppDock)
    func didSetContentView(_ view:UIView, dock:AppDock)

    func willRemoveContentView()
}

extension AppDockContent{
    public var delegate: AppDockDelegate? { return nil }

    public func willSetContentView(_ view:UIView, dock:AppDock) {}
    public func didSetContentView(_ view:UIView, dock:AppDock) {}

    public func willRemoveContentView() {}
}

public struct AppDockContentItem: AppDockContent {
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
    func reloadContentThatFits(size: CGSize) {
        reloadContent()
    }

    func reloadContent() {
        layoutIfNeeded()
    }
}
