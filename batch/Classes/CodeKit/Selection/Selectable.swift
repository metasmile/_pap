//
// Created by BLACKGENE on 04/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//TODO: transfer from CodeKit_objc
public protocol SelectableCollection {
    associatedtype Element

    var previous: Element? {get}
    var previousIndex: Int? {get}
    var current: Element? {set get}
    var currentIndex: Int? {set get}
}