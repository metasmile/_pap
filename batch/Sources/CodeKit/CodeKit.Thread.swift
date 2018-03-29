//
// Created by BLACKGENE on 29/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Thread{
    public static var currentIsMain:Bool{
        return Thread.current.name == Thread.main.name
    }
}