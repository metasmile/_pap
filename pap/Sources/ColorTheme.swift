//
//  pap.ColorTheme.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 13..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import PropertyKit

//WARNING: Do not use this CodeKit/* directly
//TODO: change to StaticVar-Generic styled common theme handler

enum ColorTheme: Int, Decodable {
    case `default`
    case dark
}

extension ColorTheme {
    var textColor: UIColor {
        switch self {
        case .dark: return UIColor(red:0.6, green:0.6, blue:0.6, alpha:1)
        default: return .black
        }
    }

    var textGrayColor: UIColor {
        switch self {
        case .dark: return .lightGray
        default: return .gray
        }
    }
    
    var barStyle: UIBarStyle {
        switch self {
        case .dark: return .black
        default: return .default
        }
    }
    
    var objectBackgroundColor: UIColor {
        switch self {
        case .dark: return UIColor(red:0.18, green:0.18, blue:0.18, alpha:1)
        default: return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .dark: return UIColor(red:0.16, green:0.16, blue:0.16, alpha:1)
        default: return .white
        }
    }
    
    var barTintColor: UIColor? {
        switch self {
        case .dark: return backgroundColor
        default: return nil
        }
    }
    
    var lineSeparatorColor: UIColor {
        switch self {
        case .dark: return UIColor(red: 80 / 255.0, green: 80 / 255.0, blue: 80 / 255.0, alpha: 1)
        default: return UIColor(red: 204 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1)
        }
    }
    
    var tintColor: UIColor {
        switch self {
            case .dark:
                return UIColor(red:0.84, green:0.84, blue:0.84, alpha:1)
            default:
                return UIApplication.shared.keyWindow?.tintColor ?? UIColor(red: 0, green: 122 / 255.0, blue: 1, alpha: 1)
        }
    }
    
    var isBarTranslucent: Bool {
        switch self {
        case .dark: return true
        default: return true
        }
    }
}

protocol ColorThemeable {
    func _applyTheme(_ colorTheme: ColorTheme)
    func applyTheme(_ colorTheme: ColorTheme)
}

fileprivate class ColorThemeManager {
    static var shared = ColorThemeManager()

    var colorTheme: ColorTheme = .dark {
        didSet {
            targets.forEach {
                $0._applyTheme(colorTheme)
            }
        }
    }
    
    func changeTheme(_ theme: ColorTheme) {
        colorTheme = theme
    }
    
    private var targets = [ColorThemeable]()
    func registerThemeable(target: ColorThemeable) {
        targets.append(target)
    }
}

extension ColorThemeable where Self: UIViewController {
    private var themeManager: ColorThemeManager {
        return ColorThemeManager.shared
    }
    
    func registerThemeable() {
        themeManager.registerThemeable(target: self)
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
    var colorTheme: ColorTheme {
        return ColorThemeManager.shared.colorTheme
    }
}

extension ColorThemeable where Self: UIViewController {
    func _applyTheme(_ colorTheme: ColorTheme) {
        navigationController?.view.backgroundColor = colorTheme.backgroundColor

        if view.backgroundColor != UIColor.clear{
            view.backgroundColor = colorTheme.backgroundColor
        }

        navigationController?.navigationBar.isTranslucent = colorTheme.isBarTranslucent
        navigationController?.navigationBar.barStyle = colorTheme.barStyle
        navigationController?.navigationBar.barTintColor = colorTheme.barTintColor
        navigationController?.navigationBar.tintColor = colorTheme.tintColor

        applyTheme(colorTheme)
    }
}

extension UIControl{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        tintColor = colorTheme.tintColor
    }
}

extension UISearchBar{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        tintColor = colorTheme.tintColor

        barStyle = colorTheme.barStyle
        barTintColor = colorTheme.barTintColor
        backgroundColor = colorTheme.backgroundColor
    }
}

extension UITableView {
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        if colorTheme == .dark && "UIPickerTableView" == String(describing: type(of: self)){
            backgroundColor = UIColor.clear
        }

        if backgroundColor != UIColor.clear{
            backgroundColor = colorTheme.backgroundColor
        }

        tintColor = colorTheme.tintColor
        separatorColor = colorTheme.lineSeparatorColor
    }
}

extension UIPickerView{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        tintColor = colorTheme.tintColor

        if colorTheme == .dark{
            for v in getAllSubviews(){
                v.backgroundColor = UIColor.clear
            }
            self.subviews[safe: 1]?.backgroundColor = colorTheme.lineSeparatorColor
            self.subviews[safe: 2]?.backgroundColor = colorTheme.lineSeparatorColor
        }

    }
}

extension UITableViewCell {
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        textLabel?.textColor = colorTheme.textColor
        accessoryView?.tintColor = colorTheme.tintColor

        if backgroundColor != UIColor.clear{
            backgroundColor = colorTheme.objectBackgroundColor
        }
    }
}

extension UITableViewPickerCell{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        titleLabel.textColor = colorTheme.textColor
        defaultValueLabelTextColor = colorTheme.textColor
        lineSeparatorColor = colorTheme.lineSeparatorColor
    }
}

extension UITableViewMultiplePickerCell{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        titleLabel.textColor = colorTheme.textColor
        defaultValueLabelTextColor = colorTheme.textColor
        lineSeparatorColor = colorTheme.lineSeparatorColor
    }
}

extension UIActivityIndicatorView{
    open override func tintColorDidChange() {
        super.tintColorDidChange()

        self.style = colorTheme == .dark ? .white : .gray
    }
}

extension UIToolbar {
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        barStyle = colorTheme.barStyle
        barTintColor = colorTheme.barTintColor
        isTranslucent = colorTheme.isBarTranslucent
    }
}
