//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UITableView{
    private static var registeredDescribersCellClass = [Int:[String:Swift.AnyClass]]()

    public func register(describer: UITableViewCellDescribable){
        if type(of: self).registeredDescribersCellClass[hashValue]==nil{
            type(of: self).registeredDescribersCellClass[hashValue] = [String:Swift.AnyClass]()
        }
        if let _ = type(of: self).registeredDescribersCellClass[hashValue]?[describer.cellIdentifier]{
            return
        }

        type(of: self).registeredDescribersCellClass[hashValue]?[describer.cellIdentifier] = describer.cellClass
        self.register(describer.cellClass, forCellReuseIdentifier: describer.cellIdentifier)
    }


    public func unregister(describer: UITableViewCellDescribable){
        type(of: self).registeredDescribersCellClass[hashValue]?[describer.cellIdentifier] = nil
    }

    public func unregisterAllRegisteredByDescribers(){
        type(of: self).registeredDescribersCellClass[hashValue] = nil
    }

}