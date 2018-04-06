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
    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool)
}

class AppDockGestureRecognizer: UIPanGestureRecognizer {
    var beginDrawerOffset: CGFloat = 0
    var beginAppContentViewOffset: CGFloat = 0
}

class AppDockView: CustomView {
    private struct DefaultPreferences{
        struct AppDockView {
            static let compactHeight: CGFloat = 44
        }

        struct DrawerView {
            static let compactHeight: CGFloat = 22
            static let topMargin: CGFloat = 5
            static let prominentHeight: CGFloat = 49
        }

        static let Accessory = AppDockContentPreferences(height: 44)
        static let Control = AppDockContentPreferences(height: 44)
    }

    @IBOutlet weak private var drawerView: DrawerView!
    @IBOutlet weak private var drawerViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appContentViewHeightLayout: NSLayoutConstraint!

    @IBOutlet weak private var topAccessoryView: UIView!
    @IBOutlet weak private var controllerView: UIView!
    @IBOutlet weak private var controllerViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var dockView: DockView!
    @IBOutlet weak private var dockViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var appCollectionView: UICollectionView!
    @IBOutlet weak private var bottomAccessoryView: UIView!
    
    var delegate: AppDockViewDelegate?
    
    var items: [AppDockItem] = [AppDockItem]() {
        didSet {
            layoutDockView()

            reloadAppDock()
        }
    }

    var barStyle: UIBarStyle = UIBarStyle.default {
        didSet {
            switch barStyle {
            case .black:
                bottomAccessoryView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
                topAccessoryView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
                controllerView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
            default:
                bottomAccessoryView.backgroundColor = .white
                topAccessoryView.backgroundColor = .white
                controllerView.backgroundColor = .white
            }
        }
    }

    override func initialize() {
        super.initialize()

        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        appCollectionView.contentInset.top = 3
        appCollectionView.contentInset.bottom = 3
        appCollectionView.register(AppDockViewCell.self, forCellWithReuseIdentifier: "STAppDockViewCell")

        drawerView.topMargin = DefaultPreferences.DrawerView.topMargin

        let gesture = AppDockGestureRecognizer(target: self, action: #selector(self.gestureDidRecognize))
        gesture.delegate = self
        addGestureRecognizer(gesture)

        let tapDrawerGesture = UITapGestureRecognizer(target: self, action: #selector(self.drawerDidTap))
        drawerView.addGestureRecognizer(tapDrawerGesture)
    }

    private func reloadAppDock() {
        appCollectionView.collectionViewLayout.prepare()
        appCollectionView.reloadData()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: drawerViewHeightLayout.constant + appContentViewHeightLayout.constant + dockViewHeightLayout.constant + bottomAccessoryView.bounds.height)
    }

    private var hasDrawer: Bool {
        let hasMultipleApps = items.count > 1
        if hasControllerPinned{
            return hasMultipleApps && accessory?.view.subviews.count ?? 0 > 0
        }
        return hasMultipleApps && controller?.view.subviews.count ?? 0 > 0
    }

    private var hasContent: Bool {
        return (preferredDrawerViewHeight + preferredAppContentViewHeight + preferredDockViewHeight) > 0
    }

    var isDrawerOpened: Bool {
        return drawerView.isOpened
    }

    /*
        layout priority : controller > accessory
    */

    // AppDock Control
    var controller: AppDockContent?{
        didSet {
            if let view = controller?.view {
                setControllerView(view, animated: true)
            }
            else {
                removeAllControllerViews()
            }
        }
    }

    var hasControllerPinned:Bool{
        return controller?.preferences?.pinned ?? false
    }

    private func hasControlView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return controllerView.subviews.contains(view)
    }

    private func setControllerView(_ view: UIView?, animated: Bool = true) {
        guard !hasControlView(view) else { return }
        controllerView.subviews.forEach({ $0.removeFromSuperview() })
        if let view = view {
            controllerView.addSubview(view)

            view.fitConstraints(to: controllerView)
        }

        layoutAppContentViews()

        if animated {
            animateAsSpringSuperviewLayoutIfNeeded()
        }
    }

    private func removeAllControllerViews(animated: Bool = true) {
        controllerView.subviews.forEach({ $0.removeFromSuperview() })

        layoutAppContentViews()

        if animated {
            animateAsSpringSuperviewLayoutIfNeeded()
        }
    }

    // AppDock accessory
    var accessory: AppDockContent?{
        didSet {
            if let view = accessory?.view {
                setTopAccessoryView(view, animated: true)
            }
            else {
                removeAllTopAccessoryViews()
            }
        }
    }

    private func hasTopAccessoryView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return topAccessoryView.subviews.contains(view)
    }
    
    private func setTopAccessoryView(_ view: UIView, animated: Bool = true) {
        guard !hasTopAccessoryView(view) else { return }
        removeAllTopAccessoryViews(animated: false)
        
        topAccessoryView.addSubview(view)
        view.fitConstraints(to: topAccessoryView)
        
        layoutAppContentViews()
        
        if animated {
            animateAsSpringSuperviewLayoutIfNeeded()
        }
    }
    
    private func removeAllTopAccessoryViews(animated: Bool = true) {
        topAccessoryView.subviews.forEach({ $0.removeFromSuperview() })
        
        layoutAppContentViews()
        
        if animated {
            animateAsSpringSuperviewLayoutIfNeeded()
        }
    }
}

extension AppDockView {
    fileprivate var preferredDrawerViewHeight: CGFloat {
        return hasDrawer ? DefaultPreferences.DrawerView.compactHeight : 0
    }
    
    fileprivate var preferredDockViewHeight: CGFloat {
        return items.count > 1 ? DefaultPreferences.AppDockView.compactHeight : 0
    }
    
    fileprivate var preferredAccessoryViewHeight: CGFloat {
        if let accessory = self.accessory{
            return accessory.preferences?.height ?? DefaultPreferences.Accessory.height
        }
        return 0
    }
    
    fileprivate var preferredControllerViewHeight: CGFloat {
        if let control = self.controller {
            return control.preferences?.height ?? DefaultPreferences.Control.height
        }
        return 0
    }
    
    fileprivate var preferredAppContentViewHeight: CGFloat {
        return preferredAccessoryViewHeight + preferredControllerViewHeight
    }

    fileprivate var constAppContentViewMaximumHeight: CGFloat {
        let TopMarginConstRatio:CGFloat = 0.84

        if let rvc = UIApplication.shared.keyWindow?.rootViewController{
            return (rvc.view.bounds.height - rvc.safeAreaInsets.top) * TopMarginConstRatio
        }

        if let h = self.superview?.bounds.height{
            return h * TopMarginConstRatio
        }

        assert(false, "not found superview and rootViewController")
        return UIScreen.main.bounds.height * TopMarginConstRatio
    }
    
    fileprivate func layoutDrawerView() {
        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        
        drawerView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutDockView() {
        dockViewHeightLayout.constant = preferredDockViewHeight
        
        dockView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutAppContentViews() {
        controllerViewHeightLayout.constant = preferredControllerViewHeight
        appContentViewHeightLayout.constant = preferredAppContentViewHeight
        
        topAccessoryView.layoutIfNeeded()
        controllerView.layoutIfNeeded()
        
        layoutDrawerView()
        
        bottomAccessoryView.isHidden = !hasContent
        
        invalidateIntrinsicContentSize()
    }
}

extension AppDockView {
    func selectItem(at indexPath: IndexPath, animated: Bool = false) {
        guard indexPath.item < items.count else { return }
        appCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        collectionView(appCollectionView, didSelectItemAt: indexPath)
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

        cell.iconImage = iconImage
        switch barStyle {
            case .black:
                cell.iconViewTintColor = .white
            default:
                cell.iconViewTintColor = .black
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
    
    @objc func drawerDidTap(sender: UITapGestureRecognizer) {
        drawerView.isOpened ? closeDrawer() : openDrawer()
    }
    
    @objc func gestureDidRecognize(sender: AppDockGestureRecognizer) {
        let translation = sender.translation(in: self)
        let velocity = sender.velocity(in: self)

        switch sender.state {
        case .began:
            sender.beginDrawerOffset = drawerViewHeightLayout.constant
            sender.beginAppContentViewOffset = appContentViewHeightLayout.constant
            break
        case .changed:
            let delta = sender.beginDrawerOffset - translation.y
            let maxHeight = max(DefaultPreferences.DrawerView.compactHeight, DefaultPreferences.DrawerView.prominentHeight)
            let minHeight = min(DefaultPreferences.DrawerView.compactHeight, DefaultPreferences.DrawerView.prominentHeight)

            appContentViewHeightLayout.constant = max(preferredAppContentViewHeight, sender.beginAppContentViewOffset - translation.y)

            if drawerView.isOpened{
                drawerView.progressToRenderOpening = remapNormalizeClamp(delta, minHeight, maxHeight)
            }else{
                drawerViewHeightLayout.constant = min(DefaultPreferences.DrawerView.prominentHeight, max(DefaultPreferences.DrawerView.compactHeight, delta))
            }
            drawerView.layoutIfNeeded()
            
            invalidateIntrinsicContentSize()
            
            if drawerView.isOpened && sender.beginDrawerOffset - translation.y < 0 {
                closeDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
            else if !drawerView.isOpened && sender.beginDrawerOffset - translation.y > DefaultPreferences.DrawerView.prominentHeight * 2 {
                openDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
        default:
            if velocity.y < 0 {
                openDrawer()
            }
            else if velocity.y > 0 {
                closeDrawer()
            }
            else {
                drawerViewHeightLayout.constant = drawerView.isOpened ? DefaultPreferences.DrawerView.prominentHeight : DefaultPreferences.DrawerView.compactHeight
                appContentViewHeightLayout.constant = drawerView.isOpened ? constAppContentViewMaximumHeight : preferredAppContentViewHeight
            }
            drawerView.layoutIfNeeded()
            
            invalidateIntrinsicContentSize()
            
            animateAsSpringSuperviewLayoutIfNeeded()
        }
    }

    func openDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? !drawerView.isOpened

        drawerView.isOpened = true
        
        drawerViewHeightLayout.constant = DefaultPreferences.DrawerView.prominentHeight
        appContentViewHeightLayout.constant = constAppContentViewMaximumHeight

        invalidateIntrinsicContentSize()
        
        animateAsSpringSuperviewLayoutIfNeeded()
        
        appContentView.layoutIfNeeded()
        
        if reloadDockContentViews {
            let contentLayoutConstant = appContentViewHeightLayout.constant - DefaultPreferences.DrawerView.compactHeight * 2
            let controllerPinned = controller?.preferences?.pinned ?? false
            let controllerLayoutConstant = controllerPinned ? preferredControllerViewHeight : contentLayoutConstant - preferredAccessoryViewHeight
            let accessoryLayoutConstant = controllerPinned ? contentLayoutConstant - preferredControllerViewHeight : preferredAccessoryViewHeight

            (accessory?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: accessoryLayoutConstant))

            (controller?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: controllerLayoutConstant))
            controllerViewHeightLayout.constant = controllerLayoutConstant
        }
        
        delegate?.appDockView(self, didOpenDrawer: true)
    }
    
    func closeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? drawerView.isOpened

        drawerView.isOpened = false

        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        appContentViewHeightLayout.constant = preferredControllerViewHeight + preferredAccessoryViewHeight
        
        invalidateIntrinsicContentSize()

        print(self.hasContent)
        animateAsSpringSuperviewLayoutIfNeeded()
        
        appContentView.layoutIfNeeded()

        if reloadDockContentViews {
            (accessory?.view as? AppDockContentView)?.reloadContent()

            (controller?.view as? AppDockContentView)?.reloadContent()
            controllerViewHeightLayout.constant = preferredControllerViewHeight
        }
        
        delegate?.appDockView(self, didOpenDrawer: false)

    }
}

// MARK: -

internal class AppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak private var selectedStateView: RoundedView!
    
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appIconView: RoundedButton!
    @IBOutlet weak private var appIconImageView: UIImageView!

    public var iconImage: UIImage? {
        get {
            return appIconImageView.image
        }
        set {
            appIconImageView.image = newValue
        }
    }

    public var iconViewTintColor: UIColor {
        get {
            return appIconImageView.tintColor
        }
        set {
            appIconImageView.tintColor = newValue
        }
    }

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
    var topMargin: CGFloat = 6
    
    // 108 x 14
    lazy private var drawerShapeLayer: CAShapeLayer = { return CAShapeLayer() }()
    lazy private var drawerShapePath: UIBezierPath = { return UIBezierPath() }()
    private let drawerShapeLayerSize = CGSize(width: 31, height: 5.8)

    var isOpened = false {
        didSet{
            layoutIfNeeded()
            progressToRenderOpening = isOpened ? 1 : 0
        }
    }

    var progressToRenderOpening:CGFloat = 0 {
        didSet {
            drawerShapePath.removeAllPoints()
            drawerShapePath.move(to: CGPoint(x: 0, y: topMargin))

            if progressToRenderOpening == 0{
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: topMargin))
            }else{
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width / 2, y: topMargin + (drawerShapeLayerSize.height * progressToRenderOpening)))
                drawerShapePath.addLine(to: CGPoint(x: drawerShapeLayerSize.width, y: topMargin))
            }
            drawerShapeLayer.path = drawerShapePath.cgPath
        }
    }

    override func initialize() {
        super.initialize()

        self.contentMode = .redraw

        drawerShapeLayer.frame.size = drawerShapeLayerSize
        drawerShapeLayer.strokeColor = UIColor(red: 199 / 255.0, green: 199 / 255.0, blue: 203 / 255.0, alpha: 1).cgColor
        drawerShapeLayer.fillColor = UIColor.clear.cgColor
        drawerShapeLayer.lineWidth = 5
        drawerShapeLayer.lineCap = kCALineCapRound
        layer.addSublayer(drawerShapeLayer)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let cornerRadius: CGFloat = 8

        let roundedRectPath = UIBezierPath(roundedRect: CGRect(x: 0, y: topMargin, width: rect.width, height: rect.height), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.saveGState()
        
        ctx?.setBlendMode(.normal)
        ctx?.setFillColor(UIColor.white.cgColor)

        ctx?.setShadow(offset: .zero, blur: topMargin, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        
        ctx?.addPath(roundedRectPath.cgPath)
        ctx?.fillPath()
        
        ctx?.restoreGState()
        
        ctx?.setLineWidth(0.5)
        ctx?.setStrokeColor(UIColor(red: 212 / 255.0, green: 211 / 255.0, blue: 212 / 255.0, alpha: 1).cgColor)
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

}
