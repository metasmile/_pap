//
// Created by BLACKGENE on 23.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

internal class AppDockDrawerView: DesignableView {
    private lazy var appIconView: AppIconRoundedView = {
        let view = AppIconRoundedView(frame: .zero)
        view.layer.borderColor = UIColor(red: 208 / 255.0, green: 208 / 255.0, blue: 208 / 255.0, alpha: 1).cgColor
        view.layer.borderWidth = 1 / UIScreen.main.scale
        return view
    }()
    
    private lazy var appIconImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private var appIconViewWidthLayout: NSLayoutConstraint?
    
    private lazy var appTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.bold)
        label.textColor = .black
        return label
    }()

    var topMargin: CGFloat = 6
    override var tintColor: UIColor! {
        didSet {
            drawerColor = tintColor

            switch tintColor {
            case UIColor.white:
                drawerStrokeColor = UIColor(red: 212 / 255.0, green: 211 / 255.0, blue: 212 / 255.0, alpha: 1)
            default:
                drawerStrokeColor = UIColor(red: 40 / 255.0, green: 40 / 255.0, blue: 40 / 255.0, alpha: 1)
            }
        }
    }
    private var drawerColor = UIColor(red:0.785, green:0.785, blue:0.79, alpha:1)
    private var drawerStrokeColor = UIColor(red:0.785, green:0.785, blue:0.79, alpha:1)

    // 108 x 14
    lazy private var drawerShapeLayer: CAShapeLayer = { return CAShapeLayer() }()
    lazy private var drawerShapePath: UIBezierPath = { return UIBezierPath() }()
    private let drawerShapeLayerSize = CGSize(width: 32, height: 5)

    var isBarHidden = false {
        didSet{
            let disableActionsToRestore = CATransaction.disableActions()
            CATransaction.setDisableActions(true)
            drawerShapeLayer.isHidden = isBarHidden
            CATransaction.setDisableActions(disableActionsToRestore)
        }
    }
    
    var showsTitle = false {
        didSet {
            appIconView.isHidden = !showsTitle
            appTitleLabel.isHidden = !showsTitle
            setNeedsDisplay()
        }
    }

    var isHandleOpened = false {
        didSet{
            layoutIfNeeded()
            handleOpeningProgress = isHandleOpened ? 1 : 0
        }
    }
    
    var handleOpeningProgress:CGFloat = 0 {
        didSet {
            drawerShapePath.removeAllPoints()
            drawerShapePath.move(to: CGPoint(x: 0, y: 0))
            drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: 0))

//            if handleOpeningProgress == 0{
//                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: centerOffsetY))
//            }else{
//                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width / 2, y: centerOffsetY + (drawerShapeLayerSize.height * handleOpeningProgress)))
//                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: centerOffsetY))
//            }
            drawerShapeLayer.path = drawerShapePath.cgPath
        }
    }

    override func initialize() {
        super.initialize()
        
        addSubview(appIconView)
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        appIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        appIconView.topAnchor.constraint(equalTo: topAnchor, constant: topMargin + 8).isActive = true
        appIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: topMargin - 16).isActive = true
        appIconViewWidthLayout = appIconView.widthAnchor.constraint(equalTo: appIconView.heightAnchor, multiplier: 1.333)
        appIconViewWidthLayout?.isActive = true
        appIconView.isHidden = true
        
        appIconView.addSubview(appIconImageView)
        appIconImageView.fitConstraints(to: appIconView)
        
        addSubview(appTitleLabel)
        appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        appTitleLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 8).isActive = true
        appTitleLabel.centerYAnchor.constraint(equalTo: appIconView.centerYAnchor).isActive = true
        appTitleLabel.isHidden = true
        
        drawerShapeLayer.frame.size = drawerShapeLayerSize
        drawerShapeLayer.strokeColor = drawerStrokeColor.cgColor
        drawerShapeLayer.fillColor = UIColor.clear.cgColor
        drawerShapeLayer.lineWidth = 4.6
        drawerShapeLayer.lineCap = kCALineCapRound
        layer.addSublayer(drawerShapeLayer)
        
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let cornerRadius: CGFloat = 8

        let roundedRectPath = UIBezierPath(roundedRect: CGRect(x: 0, y: topMargin, width: rect.width, height: max(cornerRadius * 2, rect.height - topMargin)), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))

        let ctx = UIGraphicsGetCurrentContext()
        ctx?.saveGState()

        ctx?.setBlendMode(.normal)
        ctx?.setFillColor(drawerColor.cgColor)

        ctx?.setShadow(offset: .zero, blur: topMargin, color: UIColor.black.withAlphaComponent(0.3).cgColor)

        ctx?.addPath(roundedRectPath.cgPath)
        ctx?.fillPath()

        ctx?.restoreGState()

        ctx?.setLineWidth(0.5)
        ctx?.setStrokeColor(drawerStrokeColor.cgColor)
        ctx?.move(to: CGPoint(x: cornerRadius, y: topMargin))
        ctx?.addLine(to: CGPoint(x: rect.width - cornerRadius, y: topMargin))
        ctx?.move(to: CGPoint(x: 0, y: rect.height))
        // TEST: no bottom line
        if showsTitle {
            ctx?.addLine(to: CGPoint(x: rect.width, y: rect.height))
        }
        ctx?.strokePath()
    }
    
    var compactHeight: CGFloat = 11

    override func layoutSubviews() {
        super.layoutSubviews()

        let disableActionsToRestore = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        drawerShapeLayer.frame.origin = CGPoint(x: (bounds.width - drawerShapePath.bounds.width) / 2, y: topMargin + (compactHeight - drawerShapeLayer.lineWidth) / 2)
        CATransaction.setDisableActions(disableActionsToRestore)
    }
    
    func setApp(_ app: App.Type) {
        appTitleLabel.text = app.info.displayName
        appIconImageView.image = app.info.iconBundleName?.asUIImage
        
        setNeedsLayout()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        appIconViewWidthLayout?.isActive = false
        if let _ = appIconImageView.image {
            appIconViewWidthLayout = appIconView.widthAnchor.constraint(equalTo: appIconView.heightAnchor, multiplier: 1.333)
        }
        else {
            appIconViewWidthLayout = appIconView.widthAnchor.constraint(equalToConstant: 0)
        }
        appIconViewWidthLayout?.isActive = true
    }
}

