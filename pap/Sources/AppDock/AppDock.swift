//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

// AppDock
public protocol AppDock {
    var contentLayoutState: AppDockContentLayoutState {get}
    func expandDockIfNeeded(reloadContents:Bool?) // nil means it should act with default behavior
    func contractDockIfNeeded(reloadContents:Bool?)
}

public protocol AppDockDelegate {
    func dockWillExpand(_ dock:AppDock)
    func dockDidExpand(_ dock:AppDock)

    func dockWillContract(_ dock:AppDock)
    func dockDidContract(_ dock:AppDock)
}

extension AppDockDelegate{
    func dockWillExpand(_ dock: AppDock) {}
    func dockDidExpand(_ dock: AppDock) {}

    func dockWillContract(_ dock: AppDock) {}
    func dockDidContract(_ dock: AppDock) {}
}

// AppDock Window
public enum AppDockContentLayoutState: Int{
    case minimized
    case neutralized
    case maximized
}


// AppDockContentPreferable
public protocol AppDockContentPreferable {
    var preferredHeight: CGFloat {get}
}

public struct AppDockContentPreferences: AppDockContentPreferable {
    private var _actualHeight: CGFloat = AppDockContentPreferences.kPreferredHeightLimitation
    private static let kPreferredHeightLimitation: CGFloat = 250
    public var preferredHeight: CGFloat {
        set {
            _actualHeight = min(AppDockContentPreferences.kPreferredHeightLimitation, newValue)
        }
        
        get {
            return _actualHeight
        }
    }

    init(){}

    init(preferredHeight:CGFloat){
        self.preferredHeight = preferredHeight
    }
}

// AppDockContent
public protocol AppDockContent {
    //INFO: `lazy var view: UIView = UIView()` is recommended to prevent creating new instance always.
    var view: UIView {get}
    var preferences: AppDockContentPreferable? {get}
    var delegate: AppDockDelegate? {get}

    //INFO: initializer codes should locate on `willSetContentView` (e.g. assigning delegate object)
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
