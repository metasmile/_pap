//
//  pap.AppColorTheme.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 13..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import PropertyKit

//WARNING: Do not use this CodeKit/* directly
//TODO: change to StaticVar-Generic styled common theme handler

enum AppColorTheme: Int, Decodable {
    case `default`
    case dark

    fileprivate var defaultDelegate:AppColorThemeDefaultExternalDelegate?{
        let anySelf:Any = self
        return anySelf as? AppColorThemeDefaultExternalDelegate
    }

    fileprivate var darkDelegate:AppColorDarkThemeExternalDelegate?{
        let anySelf:Any = self
        return anySelf as? AppColorDarkThemeExternalDelegate
    }
}

extension AppColorTheme {
    var textColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.textColor ?? UIColor(red:0.66, green:0.66, blue:0.66, alpha:1)
        default: return defaultDelegate?.textColor ?? .black
        }
    }

    var textLightColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.textLightColor ?? UIColor(red:0.8, green:0.8, blue:0.8, alpha:1)
        default: return defaultDelegate?.textLightColor ?? .darkText
        }
    }

    var textGrayColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.textGrayColor ?? .lightGray
        default: return defaultDelegate?.textGrayColor ?? .gray
        }
    }
    
    var barStyle: UIBarStyle {
        switch self {
        case .dark: return darkDelegate?.barStyle ?? .black
        default: return defaultDelegate?.barStyle ?? .default
        }
    }
    
    var objectBackgroundColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.objectBackgroundColor ?? UIColor(red:0.18, green:0.18, blue:0.18, alpha:1)
        default: return defaultDelegate?.objectBackgroundColor ?? .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.backgroundColor ?? UIColor(red:0.16, green:0.16, blue:0.16, alpha:1)
        default: return defaultDelegate?.backgroundColor ?? .white
        }
    }
    
    var barTintColor: UIColor? {
        switch self {
        case .dark: return darkDelegate?.barTintColor ?? backgroundColor
        default: return defaultDelegate?.barTintColor ?? nil
        }
    }
    
    var lineSeparatorColor: UIColor {
        switch self {
        case .dark: return darkDelegate?.lineSeparatorColor ?? UIColor(red: 80 / 255.0, green: 80 / 255.0, blue: 80 / 255.0, alpha: 1)
        default: return defaultDelegate?.lineSeparatorColor ?? UIColor(red: 204 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1)
        }
    }
    
    var tintColor: UIColor {
        switch self {
            case .dark:
                return darkDelegate?.tintColor ?? UIColor(red:0.84, green:0.84, blue:0.84, alpha:1)
            default:
                if let c = defaultDelegate?.tintColor{
                    return c
                }
                return UIApplication.shared.keyWindow?.tintColor ?? UIColor(red: 0, green: 122 / 255.0, blue: 1, alpha: 1)
        }
    }
    
    var isBarTranslucent: Bool {
        switch self {
        case .dark: return darkDelegate?.isBarTranslucent ?? true
        default: return defaultDelegate?.isBarTranslucent ?? true
        }
    }
}

protocol AppColorThemeable {
    func _applyTheme(_ colorTheme: AppColorTheme)
    func applyTheme(_ colorTheme: AppColorTheme)
}

fileprivate class AppColorThemeManager {
    static var shared = AppColorThemeManager()

    var colorTheme: AppColorTheme = {
        let anyType:Any.Type = AppColorTheme.self
        return (anyType as? AppColorDefaultThemeExternalDelegate.Type)?.theme ?? .default
    }() {
        didSet {
            targets.forEach {
                $0._applyTheme(colorTheme)
            }
        }
    }
    
    func changeTheme(_ theme: AppColorTheme) {
        colorTheme = theme
    }
    
    private var targets = [AppColorThemeable]()
    func registerThemeable(target: AppColorThemeable) {
        targets.append(target)
    }
}

extension AppColorThemeable where Self: UIViewController {
    private var themeManager: AppColorThemeManager {
        return AppColorThemeManager.shared
    }
    
    func registerThemeable() {
        themeManager.registerThemeable(target: self)
        setColorTheme(themeManager.colorTheme)
    }
    
    func setColorTheme(_ colorTheme: AppColorTheme, animated: Bool = false) {
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
    var colorTheme: AppColorTheme {
        return AppColorThemeManager.shared.colorTheme
    }
}

extension AppColorThemeable where Self: UIViewController {
    func _applyTheme(_ colorTheme: AppColorTheme) {
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

extension UIButton{
    open override func tintColorDidChange() {
        if self.buttonType != .system{
            super.tintColorDidChange()
        }
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

extension UIScrollView {
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        indicatorStyle = colorTheme == .dark ? .white : .default
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
