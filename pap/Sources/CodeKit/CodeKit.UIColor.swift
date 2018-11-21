//
//  CodeKit.UIColor.swift
//  pap
//
//  Created by HYOJIN MO on 21/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
    }
    
    convenience init(rgba: Int) {
        self.init(
            red: (rgba >> 24) & 0xFF,
            green: (rgba >> 16) & 0xFF,
            blue: (rgba >> 8) & 0xFF,
            alpha: (rgba >> 0) & 0xFF
        )
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: (rgb >> 0) & 0xFF
        )
    }
    
    convenience init(hexString: String) {
        var string = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if string.hasPrefix("#") {
            string.remove(at: string.startIndex)
        }
        
        var scannedValue: UInt32 = 0
        Scanner(string: string).scanHexInt32(&scannedValue)
        
        let hex = Int(scannedValue)
        
        switch string.count {
        case 6: self.init(rgb: hex)
        case 8: self.init(rgba: hex)
        default: self.init(rgb: hex)
        }
    }
    
    func hexCode() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        if a < 1 {
            return String(format: "#%02X%02X%02X%02X", Int(r * 0xFF), Int(g * 0xFF), Int(b * 0xFF), Int(a * 0xFF))
        }
        else {
            return String(format: "#%02X%02X%02X", Int(r * 0xFF), Int(g * 0xFF), Int(b * 0xFF))
        }
    }
    
    func rgba() -> Int {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return Int(r * 0xFF) << 24 | Int(g * 0xFF) << 16 | Int(b * 0xFF) << 8 | Int(a * 0xFF)
    }
}

extension UIColor {
    struct FlatColor {
        struct Green {
            static let Fern = UIColor(rgb: 0x6ABB72)
            static let MountainMeadow = UIColor(rgb: 0x3ABB9D)
            static let ChateauGreen = UIColor(rgb: 0x4DA664)
            static let PersianGreen = UIColor(rgb: 0x2CA786)
        }
        
        struct Blue {
            static let PictonBlue = UIColor(rgb: 0x5CADCF)
            static let Mariner = UIColor(rgb: 0x3585C5)
            static let CuriousBlue = UIColor(rgb: 0x4590B6)
            static let Denim = UIColor(rgb: 0x2F6CAD)
            static let Chambray = UIColor(rgb: 0x485675)
            static let BlueWhale = UIColor(rgb: 0x29334D)
        }
        
        struct Violet {
            static let Wisteria = UIColor(rgb: 0x9069B5)
            static let BlueGem = UIColor(rgb: 0x533D7F)
        }
        
        struct Yellow {
            static let Energy = UIColor(rgb: 0xF2D46F)
            static let Turbo = UIColor(rgb: 0xF7C23E)
        }
        
        struct Orange {
            static let NeonCarrot = UIColor(rgb: 0xF79E3D)
            static let Sun = UIColor(rgb: 0xEE7841)
        }
        
        struct Red {
            static let TerraCotta = UIColor(rgb: 0xE66B5B)
            static let Valencia = UIColor(rgb: 0xCC4846)
            static let Cinnabar = UIColor(rgb: 0xDC5047)
            static let WellRead = UIColor(rgb: 0xB33234)
        }
        
        struct Gray {
            static let AlmondFrost = UIColor(rgb: 0xA28F85)
            static let WhiteSmoke = UIColor(rgb: 0xEFEFEF)
            static let Iron = UIColor(rgb: 0xD1D5D8)
            static let IronGray = UIColor(rgb: 0x75706B)
        }
    }
}
