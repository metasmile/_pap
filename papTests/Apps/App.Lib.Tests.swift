//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import XCTest
import Foundation

@testable import pap

class AppTests: PHAssetsXCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_textparsers(){
        for number in [
            "FD2324FD2324"
            ,"FD2324FD324"
            ,"FD2324 AFD2324"
            ,"FD2324 JBU524"
            ,"FD2324 BAX JB 5424"
            ,"JB 5424"
            ,"DL1"
            ," DL1"
            ,"BA2491A"
            ,"  BA2491A"
            ,"  BA2491A    "
            ,"BA 2491A"
            ,"AAL1"
            ,"AA L1"
            ,"4BA2491A"
            ,"LH123G"
        ]{
            print(VisionTextFlightNumberParser.matchesInText(text: number))
        }

    }

}
