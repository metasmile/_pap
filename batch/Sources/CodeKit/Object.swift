//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class Object: NSObject{
    public lazy var uuid:String = UUID().uuidString
}

public class ItemObject: Object{
    public var index:UInt = 0
    public var metaData:[String:Any]?
    public var createdTime:TimeInterval

    override init(){
        createdTime = NSDate().timeIntervalSince1970
        super.init()
    }
}

public class BindableObject<BindingType>: ItemObject{
    public typealias conformsBindingObjectType = BindingType
    private(set) public var bindedObject: conformsBindingObjectType?

    init(_ bindingObject:conformsBindingObjectType?=nil){
        super.init()
        self.bindedObject = self.bind(bindingObject)
    }

    func bind(_ bindingObject:conformsBindingObjectType?) -> conformsBindingObjectType?{
        return bindingObject
    }
}
