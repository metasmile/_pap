//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import UIKit

// PhotoPicker -> App
public protocol PhotoPickerViewControllerDelegatableApp: App {
    var appIcon: UIImage? {get}
    var doneButtonTitle:String? {get}
    var titleWillBegin:String? {get}
    func titleDidUpdate(progress: Float) -> String?
    var titleWillCancel:String? {get}
    var titleWillFinalize:String? {get}
}

extension PhotoPickerViewControllerDelegatableApp {
    public var appIcon: UIImage? {
        return type(of: self).info.icon?.asUIImage
    }
    public var doneButtonTitle: String? {
        return type(of: self).info.displayName
    }

    public var titleWillBegin:String? {
        return nil
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return nil
    }

    public var titleWillCancel:String? {
        return nil
    }

    public var titleWillFinalize:String? {
        return nil
    }
}
