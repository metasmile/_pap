//
//  AppDock.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 1..
//  Copyright © 2017년 Stells. All rights reserved.
//
//  App Dock
//    Collection of apps for batch processing
//    iMessage Sticker App Dock inspired
//    AppDockItem > AppDockViewCell

import UIKit

struct AppDockItem {
    var app: App.Type
}

// MARK: -

protocol AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem)
}

internal class AppDockGestureRecognizer: UIPanGestureRecognizer {
    var beginDrawerOffset: CGFloat = 0
    var beginAppContentViewOffset: CGFloat = 0
}

class AppDockView: CustomView {
    private struct AppDockPreferences {
        static let compactHeight: CGFloat = 44
    }
    
    private struct PreviewPreferences {
        static let compactHeight: CGFloat = 44
    }
    
    private struct AppConfigPreferences {
        static let compactHeight: CGFloat = 44
    }
    
    private struct DrawerPreferences {
        static let topMargin: CGFloat = 5
        static let compactHeight: CGFloat = 20
        static let prominentHeight: CGFloat = 44
    }
    
    @IBOutlet weak var drawerView: DrawerView!
    @IBOutlet weak var drawerViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var appContentView: UIView!
    @IBOutlet weak var appContentViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var topAccessoryView: UIView!
    @IBOutlet weak var appConfigView: UIView!
    @IBOutlet weak var appConfigViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var dockView: DockView!
    @IBOutlet weak var dockViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var appCollectionView: UICollectionView!
    @IBOutlet weak var bottomAccessoryView: UIView!
    
    var delegate: AppDockViewDelegate?
    
    var items: [AppDockItem] = [AppDockItem]() {
        didSet {
            layoutDockView()
            
            reloadAppDock()
        }
    }
    
    var hasDrawer: Bool {
        return (appConfigView.subviews.count > 0 && items.count > 1)
    }
    
    var hasAppDockContent: Bool {
        return (preferredDrawerViewHeight + preferredAppContentViewHeight + preferredDockViewHeight) > 0
    }
    
    override func initialize() {
        super.initialize()
        
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        appCollectionView.contentInset.top = 3
        appCollectionView.contentInset.bottom = 3
        appCollectionView.register(AppDockViewCell.self, forCellWithReuseIdentifier: "STAppDockViewCell")
        
        drawerView.topMargin = DrawerPreferences.topMargin
        
        let gestuer = AppDockGestureRecognizer(target: self, action: #selector(self.gestureDidRecognize))
        gestuer.delegate = self
        addGestureRecognizer(gestuer)
    }
    
    func reloadAppDock() {
        appCollectionView.collectionViewLayout.prepare()
        appCollectionView.reloadData()
    }
    
    var barStyle: UIBarStyle = UIBarStyle.default {
        didSet {
            switch barStyle {
            case .black:
                bottomAccessoryView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
                topAccessoryView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
                appConfigView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
            default:
                bottomAccessoryView.backgroundColor = .white
                topAccessoryView.backgroundColor = .white
                appConfigView.backgroundColor = .white
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: drawerViewHeightLayout.constant + appContentViewHeightLayout.constant + dockViewHeightLayout.constant + bottomAccessoryView.bounds.height)
    }
    
    func setTopAccessoryView(_ view: UIView?, animated: Bool = true) {
        guard !hasTopAccessoryView(view) else { return }
        removeAllTopAccessoryViews()
        
        guard let view = view else { return }
        
        topAccessoryView.addSubview(view)
        view.fitConstraints(to: topAccessoryView)
        
        layoutAppContentView()
        
        if animated {
            animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    func removeTopAccessoryView(_ view: UIView, animated: Bool = true) {
        guard hasTopAccessoryView(view) else { return }
        
        view.removeFromSuperview()
        
        layoutAppContentView()
        
        if animated {
            animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    private func removeAllTopAccessoryViews() {
        topAccessoryView.subviews.forEach({ $0.removeFromSuperview() })
        
        layoutAppContentView()
    }
    
    fileprivate func hasTopAccessoryView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return topAccessoryView.subviews.contains(view)
    }
    
    func setAppConfigView(_ view: UIView?, animated: Bool = true) {
        guard !hasAppConfigView(view) else { return }
        appConfigView.subviews.forEach({ $0.removeFromSuperview() })
        if let view = view {
            appConfigView.addSubview(view)
            
            view.fitConstraints(to: appConfigView)
        }
        
        layoutAppContentView()
        
        if animated {
            animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    func removeAllAppConfigViews(animated: Bool = true) {
        appConfigView.subviews.forEach({ $0.removeFromSuperview() })
        
        layoutAppContentView()
        
        if animated {
            animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    fileprivate func hasAppConfigView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return appConfigView.subviews.contains(view)
    }
}

extension AppDockView {
    fileprivate var preferredDrawerViewHeight: CGFloat {
        return hasDrawer ? DrawerPreferences.compactHeight : 0
    }
    
    fileprivate var preferredDockViewHeight: CGFloat {
        return items.count > 1 ? AppDockPreferences.compactHeight : 0
    }
    
    fileprivate var preferredPreviewViewHeight: CGFloat {
        return topAccessoryView.subviews.count == 0 ? 0 : PreviewPreferences.compactHeight
    }
    
    fileprivate var preferredAppConfigViewHeight: CGFloat {
        return appConfigView.subviews.count == 0 ? 0 : AppConfigPreferences.compactHeight
    }
    
    fileprivate var preferredAppContentViewHeight: CGFloat {
        return preferredPreviewViewHeight + preferredAppConfigViewHeight
    }
    
    fileprivate func layoutDrawerView() {
        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        
        drawerView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
        
        drawerView.setNeedsDisplay()
    }
    
    fileprivate func layoutDockView() {
        dockViewHeightLayout.constant = preferredDockViewHeight
        
        dockView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutAppContentView() {
        appConfigViewHeightLayout.constant = preferredAppConfigViewHeight
        appContentViewHeightLayout.constant = preferredAppContentViewHeight
        
        topAccessoryView.layoutIfNeeded()
        appConfigView.layoutIfNeeded()
        
        layoutDrawerView()
        
        bottomAccessoryView.isHidden = !hasAppDockContent
        
        invalidateIntrinsicContentSize()
    }
}

extension AppDockView {
    func selectItem(at indexPath: IndexPath, animated: Bool = false) {
        guard indexPath.item < items.count else { return }
        appCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        collectionView(appCollectionView, didSelectItemAt: indexPath)
        closeDrawer()
    }
}

// MARK: -

extension AppDockView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STAppDockViewCell", for: indexPath) as! AppDockViewCell
        let app = items[indexPath.item].app
        let iconImage = app.info.icon?.asUIImage ?? R.image.blankAppIcon()

        let status = AppCenter.default.persistedStatus(for: app)
//        .unsupported --> app is not supported PersistableApp, or app.phase == develop/beta mode
//        .released
//        .updated
//        .used

        cell.appIconImageView.image = iconImage//iconImage.withRenderingMode(.alwaysTemplate)
        switch barStyle {
            case .black:
                cell.appIconImageView.tintColor = .white
            default:
                cell.appIconImageView.tintColor = .black
        }
        return cell
    }
}

extension AppDockView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.appDockView(self, didSelectItemWith: items[indexPath.item])
    }
}

extension AppDockView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 40 x 30 iMessage App Icon Size
        let contentSize = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).size
        return CGSize(width: contentSize.height * 1.333, height: contentSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let itemSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section))
        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: section))

        let minimumInteritemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt:section)
        let combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1)  * minimumInteritemSpacing)

        let padding = (collectionView.frame.width - combinedItemWidth) / 2
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.collectionView(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt:section)
    }
}

extension AppDockView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return hasDrawer
    }
    
    @objc func gestureDidRecognize(sender: AppDockGestureRecognizer) {
        let translation = sender.translation(in: self)
        switch sender.state {
        case .began:
            sender.beginDrawerOffset = drawerViewHeightLayout.constant
            sender.beginAppContentViewOffset = appContentViewHeightLayout.constant
            break
        case .changed:
            drawerViewHeightLayout.constant = min(DrawerPreferences.prominentHeight, max(DrawerPreferences.compactHeight, sender.beginDrawerOffset - translation.y))
            appContentViewHeightLayout.constant = max(preferredAppContentViewHeight, sender.beginAppContentViewOffset - translation.y)
            
            drawerView.layoutIfNeeded()
            drawerView.setNeedsDisplay()
            invalidateIntrinsicContentSize()
            
            if drawerView.isOpened && sender.beginDrawerOffset - translation.y < 0 {
                closeDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
            else if !drawerView.isOpened && sender.beginDrawerOffset - translation.y > DrawerPreferences.prominentHeight * 2 {
                openDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
        default:
            if sender.velocity(in: self).y < 0 {
                openDrawer()
            }
            else {
                closeDrawer()
            }
            drawerView.layoutIfNeeded()
            drawerView.setNeedsDisplay()
            invalidateIntrinsicContentSize()
            
            animateUsingSpringIfLayoutConstraintsChanged()
        }
    }
    
    func openDrawer() {
        drawerView.isOpened = true
        
        drawerViewHeightLayout.constant = DrawerPreferences.prominentHeight
        appContentViewHeightLayout.constant = (superview?.bounds ?? UIScreen.main.bounds).height / 2
        
        invalidateIntrinsicContentSize()
        
        animateUsingSpringIfLayoutConstraintsChanged()
    }
    
    func closeDrawer() {
        drawerView.isOpened = false
        
        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        appContentViewHeightLayout.constant = preferredAppConfigViewHeight + preferredPreviewViewHeight
        
        invalidateIntrinsicContentSize()
        
        animateUsingSpringIfLayoutConstraintsChanged()
    }
}

// MARK: -

internal class AppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak var selectedStateView: RoundedView!
    
    @IBOutlet weak var appContentView: UIView!
    @IBOutlet weak var appIconView: RoundedButton!
    @IBOutlet weak var appIconImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isSelected = false
    }
    
    override var isSelected: Bool {
        didSet {
            selectedStateView.isHidden = !isSelected
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        appIconView.cornerRadius = appIconView.bounds.height * 0.5
    }
}

// MARK: -

internal class DockView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setLineWidth(0.5)
        ctx?.setStrokeColor(UIColor(red: 204 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1).cgColor)
        ctx?.move(to: .zero)
        ctx?.addLine(to: CGPoint(x: rect.width, y: 0))
        ctx?.move(to: CGPoint(x: 0, y: rect.height))
        ctx?.addLine(to: CGPoint(x: rect.width, y: rect.height))
        ctx?.strokePath()
    }
}

// MARK: - Drawer View

internal class DrawerView: DesignableView {
    var topMargin: CGFloat = 5
    
    // 108 x 14
    private var drawerShapeLayer: CAShapeLayer!
    private var drawerClosedShapePath: UIBezierPath!
    private var drawerOpenedShapePath: UIBezierPath!
    
    override func initialize() {
        super.initialize()
        
        let drawerShapeLayerSize = CGSize(width: 36, height: 4)
        
        drawerClosedShapePath = UIBezierPath()
        drawerClosedShapePath.move(to: CGPoint(x: 0, y: topMargin - 1))
        drawerClosedShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: topMargin - 1))
        
        drawerShapeLayer = CAShapeLayer()
        drawerShapeLayer.frame.size = drawerShapeLayerSize
        drawerShapeLayer.path = drawerClosedShapePath.cgPath
        drawerShapeLayer.strokeColor = UIColor(red: 199 / 255.0, green: 199 / 255.0, blue: 203 / 255.0, alpha: 1).cgColor
        drawerShapeLayer.lineWidth = drawerShapeLayerSize.height
        drawerShapeLayer.lineCap = kCALineCapRound
        layer.addSublayer(drawerShapeLayer)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let cornerRadius: CGFloat = topMargin
        
        let roundedRectPath = UIBezierPath(roundedRect: CGRect(x: 0, y: topMargin, width: rect.width, height: rect.height - topMargin), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.saveGState()
        
        ctx?.setBlendMode(.normal)
        ctx?.setFillColor(UIColor.white.cgColor)
        ctx?.setShadow(offset: .zero, blur: topMargin, color: UIColor.black.withAlphaComponent(0.2).cgColor)
        
        ctx?.addPath(roundedRectPath.cgPath)
        ctx?.fillPath()
        
        ctx?.restoreGState()
        
        ctx?.setLineWidth(0.5)
        ctx?.setStrokeColor(UIColor(red: 213 / 255.0, green: 212 / 255.0, blue: 213 / 255.0, alpha: 1).cgColor)
        ctx?.move(to: CGPoint(x: cornerRadius, y: topMargin))
        ctx?.addLine(to: CGPoint(x: rect.width - cornerRadius, y: topMargin))
        ctx?.move(to: CGPoint(x: 0, y: rect.height))
        ctx?.addLine(to: CGPoint(x: rect.width, y: rect.height))
        ctx?.strokePath()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.setDisableActions(true)
        drawerShapeLayer.position = center
        CATransaction.setDisableActions(false)
    }
    
    var isOpened = false
}
