//
//  ColorThemeManager.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 13..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import PropertyKit

enum ColorTheme: Int, Decodable {
    case light
    case dark
}

extension ColorTheme {
    var tintColor: UIColor {
        switch self {
        case .dark: return UIColor.black
        default: return UIApplication.shared.keyWindow?.tintColor ?? .white
        }
    }
}

protocol ColorThemable {
    func applyTheme(_ colorTheme: ColorTheme)
}

fileprivate class ColorThemeManager {
    static var shared = ColorThemeManager()
    
    var colorTheme: ColorTheme = .dark {
        didSet {
            targets.forEach {
                $0.applyTheme(colorTheme)
            }
        }
    }
    
    func changeTheme(_ theme: ColorTheme) {
        colorTheme = theme
    }
    
    private var targets = [ColorThemable]()
    func registerThemable(target: ColorThemable) {
        targets.append(target)
    }
}

extension ColorThemable where Self: UIViewController {
    private var themeManager: ColorThemeManager {
        return ColorThemeManager.shared
    }
    
    func registerThemable() {
        themeManager.registerThemable(target: self)
        setColorTheme(themeManager.colorTheme)
    }
    
    func setColorTheme(_ colorTheme: ColorTheme, animated: Bool = false) {
        if let window = UIApplication.shared.keyWindow, animated {
            guard themeManager.colorTheme != colorTheme else { return }
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.themeManager.colorTheme = colorTheme
            }, completion: nil)
        }
        else {
            themeManager.colorTheme = colorTheme
        }
    }
}
