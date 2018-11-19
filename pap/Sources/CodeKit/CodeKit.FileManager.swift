//
// Created by BLACKGENE on 26.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension FileManager {
    func clearTemporaryDirectory() {
        if let urls = try? FileManager.default.contentsOfDirectory(at: FileURL.tempBase, includingPropertiesForKeys: nil, options: []){
            for url in urls{
                print("cleared tmp:", url)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}