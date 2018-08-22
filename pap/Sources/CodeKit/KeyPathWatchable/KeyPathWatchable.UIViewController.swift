//
// Created by BLACKGENE on 8/22/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

class KeyPathWatchableUIViewController: UIViewController, KeyPathWatchable{
    @objc dynamic
    var wasLoaded:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        wasLoaded = true
    }
}
