//
// Created by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol ChargeableApp{

    //INFO:
    // nil -> free
    var chargesRequired:[Chargeable]?{get}
}