//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UITableView{
    public func register(describer:UITableViewDescribable){
        self.register(describer.cellClass, forCellReuseIdentifier: describer.identifier)
    }
}