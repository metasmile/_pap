//
// Created by BLACKGENE on 23.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

internal class AppDockDrawerView: DesignableView {

    var topMargin: CGFloat = 6
    override var tintColor: UIColor! {
        didSet {
            drawerColor = tintColor

            switch tintColor {
            case .white:
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

    var isHandleOpened = false {
        didSet{
            layoutIfNeeded()
            handleOpeningProgress = isHandleOpened ? 1 : 0
        }
    }

    var handleOpeningProgress:CGFloat = 0 {
        didSet {
            drawerShapePath.removeAllPoints()
            drawerShapePath.move(to: CGPoint(x: 0, y: topMargin))

            if handleOpeningProgress == 0{
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: topMargin))
            }else{
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width / 2, y: topMargin + (drawerShapeLayerSize.height * handleOpeningProgress)))
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: topMargin))
            }
            drawerShapeLayer.path = drawerShapePath.cgPath
        }
    }

    override func initialize() {
        super.initialize()

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
//        ctx?.addLine(to: CGPoint(x: rect.width, y: rect.height))
        ctx?.strokePath()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let disableActionsToRestore = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        drawerShapeLayer.position = center
        CATransaction.setDisableActions(disableActionsToRestore)
    }
}

