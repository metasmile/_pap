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
    case `default`
    case black
}

extension ColorTheme {
    var textColor: UIColor {
        switch self {
        case .black: return .white
        default: return .black
        }
    }
    
    var barStyle: UIBarStyle {
        switch self {
        case .black: return .black
        default: return .default
        }
    }
    
    var themeColor: UIColor {
        switch self {
        case .black: return UIColor(red:0.15, green:0.15, blue:0.15, alpha:1)
        default: return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .black: return UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
        default: return .white
        }
    }
    
    var barTintColor: UIColor? {
        switch self {
        case .black: return UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
        default: return nil
        }
    }
    
    var lineSeparatorColor: UIColor {
        switch self {
        case .black: return UIColor(red: 80 / 255.0, green: 80 / 255.0, blue: 80 / 255.0, alpha: 1)
        default: return UIColor(red: 204 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1)
        }
    }
    
    var tintColor: UIColor? {
        switch self {
        case .black: return .white
        default: return UIApplication.shared.keyWindow?.tintColor
        }
    }
    
    var isBarTranslucent: Bool {
        switch self {
        case .black: return true
        default: return true
        }
    }
}

protocol ColorThemable {
    func _applyTheme(_ colorTheme: ColorTheme)
    func applyTheme(_ colorTheme: ColorTheme)
}

fileprivate class ColorThemeManager {
    static var shared = ColorThemeManager()
    
    var colorTheme: ColorTheme = .black {
        didSet {
            targets.forEach {
                $0._applyTheme(colorTheme)
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

extension UIView {
    var currentTheme: ColorTheme {
        return ColorThemeManager.shared.colorTheme
    }
}

extension ColorThemable where Self: UIViewController {
    func _applyTheme(_ colorTheme: ColorTheme) {
        navigationController?.view.backgroundColor = colorTheme.backgroundColor
        view.backgroundColor = colorTheme.backgroundColor
        
        navigationController?.navigationBar.isTranslucent = colorTheme.isBarTranslucent
        navigationController?.navigationBar.barStyle = colorTheme.barStyle
        navigationController?.navigationBar.barTintColor = colorTheme.barTintColor
        navigationController?.navigationBar.tintColor = colorTheme.tintColor
        
        applyTheme(colorTheme)
    }
}

extension UITableView {
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        backgroundColor = currentTheme.backgroundColor
        tintColor = currentTheme.tintColor
        separatorColor = currentTheme.lineSeparatorColor
    }
}

extension UITableViewCell {
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        textLabel?.textColor = tintColor
        backgroundColor = currentTheme.themeColor
    }
}
