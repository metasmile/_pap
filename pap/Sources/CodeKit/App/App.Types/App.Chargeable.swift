//
// Created by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol ChargeableApp :App{

    //INFO:
    // nil -> free
    static var localCharges:[Charge]? {get}
}