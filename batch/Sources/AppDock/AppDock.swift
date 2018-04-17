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

    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var drawerView: DrawerView!
    @IBOutlet weak private var drawerViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appContentViewHeightLayout: NSLayoutConstraint!

    @IBOutlet weak private var topAccessoryView: UIView!
    @IBOutlet weak private var controllerView: UIView!
    @IBOutlet weak private var controllerViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var dockView: DockView!
    @IBOutlet weak private var dockViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak private var appCollectionView: DockCollectionView!
    @IBOutlet weak private var appCollectionViewHeightLayout: NSLayoutConstraint!
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
                backgroundView.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
            default:
                backgroundView.backgroundColor = .white
            }
        }
    }

    override func initialize() {
        super.initialize()

        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        appCollectionView.contentInset.top = 0
        appCollectionView.contentInset.bottom = 0
        appCollectionView.register(AppDockViewCell.self, forCellWithReuseIdentifier: "AppDockViewCell")

        drawerView.topMargin = DefaultPreferences.DrawerView.topMargin

        let gesture = AppDockGestureRecognizer(target: self, action: #selector(self.gestureDidRecognize))
        gesture.delegate = self
        addGestureRecognizer(gesture)

        let tapDrawerGesture = UITapGestureRecognizer(target: self, action: #selector(self.drawerDidTap))
        drawerView.addGestureRecognizer(tapDrawerGesture)
    }

    private func reloadAppDock() {
        appCollectionView.reloadData()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: drawerViewHeightLayout.constant + appContentViewHeightLayout.constant + dockViewHeightLayout.constant + bottomAccessoryView.bounds.height)
    }

    private var hasDrawer: Bool {
        let hasMultipleApps = items.count > 1
        if hasControllerPinned{
            return hasMultipleApps && topAccessoryView.subviews.count > 0
        }
        return hasMultipleApps && controllerView.subviews.count > 0
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

                DispatchQueue.main.async{
                    self.controller?.didSetContentView(view)
                }
            }
            else {
                controller?.willRemoveContentView()
                removeAllControllerViews()
            }
        }
    }

    var hasControllerPinned:Bool{
        return controller?.preferences?.pinned == true
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

                DispatchQueue.main.async{
                    self.accessory?.didSetContentView(view)
                }
            }
            else {
                accessory?.willRemoveContentView()
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
            return accessory.preferences?.minimumHeight ?? DefaultPreferences.Accessory.minimumHeight
        }
        return 0
    }
    
    fileprivate var preferredControllerViewHeight: CGFloat {
        if let control = self.controller {
            return control.preferences?.minimumHeight ?? DefaultPreferences.Control.minimumHeight
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

        let isDockViewAppearing = preferredDockViewHeight != 0
        dockView.isHidden = !isDockViewAppearing
        
        dockView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutAppContentViews() {
        controllerViewHeightLayout.constant = preferredControllerViewHeight
        appContentViewHeightLayout.constant = preferredAppContentViewHeight
        
        topAccessoryView.layoutIfNeeded()
        controllerView.layoutIfNeeded()
        
        layoutDrawerView()
        
        backgroundView.isHidden = !hasContent
        
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppDockViewCell", for: indexPath) as! AppDockViewCell
        let app = items[indexPath.item].app
        cell.setApp(app, at: indexPath)
        
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
        zoomOutAppCollectionView(delay: 0)
        delegate?.appDockView(self, didSelectItemWith: items[indexPath.item])
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
            controllerViewHeightLayout.constant = controller?.preferences?.pinned == true ? preferredControllerViewHeight : appContentViewHeightLayout.constant - preferredAccessoryViewHeight

            if drawerView.isOpened{
                drawerView.progressToRenderOpening = remapNormalizeClamp(delta, minHeight, maxHeight)
                topAccessoryView.layoutIfNeeded()
                controllerView.layoutIfNeeded()
            }else{
                drawerViewHeightLayout.constant = min(DefaultPreferences.DrawerView.prominentHeight, max(DefaultPreferences.DrawerView.compactHeight, delta))
            }
            
            appContentView.layoutIfNeeded()
            
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
                drawerView.isOpened ? openDrawer() : closeDrawer()
            }
        }
    }

    func openDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? !drawerView.isOpened

        drawerView.isOpened = true
        
        drawerViewHeightLayout.constant = DefaultPreferences.DrawerView.prominentHeight
        appContentViewHeightLayout.constant = constAppContentViewMaximumHeight
        
        let contentLayoutConstant = appContentViewHeightLayout.constant
        let controllerPinned = controller?.preferences?.pinned ?? false
        let controllerLayoutConstant = controllerPinned ? preferredControllerViewHeight : contentLayoutConstant - preferredAccessoryViewHeight
        let accessoryLayoutConstant = controllerPinned ? contentLayoutConstant - preferredControllerViewHeight : preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = controllerLayoutConstant
        
        appContentView.layoutIfNeeded()
        
        invalidateIntrinsicContentSize()
        
        animateAsSpringSuperviewLayoutIfNeeded()
        
        if reloadDockContentViews {
            (accessory?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: accessoryLayoutConstant))

            (controller?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: controllerLayoutConstant))
        }
        
        delegate?.appDockView(self, didOpenDrawer: true)
    }
    
    func closeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? drawerView.isOpened

        drawerView.isOpened = false

        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        appContentViewHeightLayout.constant = preferredControllerViewHeight + preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = preferredControllerViewHeight
        
        appContentView.layoutIfNeeded()
        
        invalidateIntrinsicContentSize()

        animateAsSpringSuperviewLayoutIfNeeded()

        if reloadDockContentViews {
            (accessory?.view as? AppDockContentView)?.reloadContent()

            (controller?.view as? AppDockContentView)?.reloadContent()
        }
        
        delegate?.appDockView(self, didOpenDrawer: false)
    }
}

// MARK: -

extension AppDockView: UIScrollViewDelegate {
    func zoomInAppCollectionView() {
        guard (appCollectionView.collectionViewLayout as? AppCollectionViewLayout)?.layoutMetrics == .compact else { return }
        
        let promptLayout = AppCollectionViewLayout()
        promptLayout.layoutMetrics = .prominent
        
        appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.prominentHeight
        UIView.animateAsSpring(0.5, delay: 0, animations: {
            self.appCollectionView.superview?.layoutIfNeeded()
            self.appCollectionView.setCollectionViewLayout(promptLayout, animated: false)
        }, completion: nil)
    }
    
    func zoomOutAppCollectionView(delay: Double = 0.5) {
        guard (appCollectionView.collectionViewLayout as? AppCollectionViewLayout)?.layoutMetrics == .prominent else { return }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) { [unowned self] in
            guard !self.appCollectionView.isDragging else { return }
            
            let promptLayout = AppCollectionViewLayout()
            promptLayout.layoutMetrics = .compact
            
            self.appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.compactHeight
            UIView.animateAsSpring(0.5, delay: 0, animations: {
                self.appCollectionView.superview?.layoutIfNeeded()
                self.appCollectionView.setCollectionViewLayout(promptLayout, animated: false)
            }, completion: nil)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        zoomInAppCollectionView()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        zoomOutAppCollectionView()
    }
}

// MARK: -

class AppCollectionViewLayout: UICollectionViewLayout {
    enum LayoutMetrics {
        case compact
        case prominent
    }
    
    var layoutMetrics: LayoutMetrics = .compact {
        didSet {
            invalidateLayout()
        }
    }
    
    struct LayoutConstants {
        static let compactHeight: CGFloat = 44
        static let prominentHeight: CGFloat = 75
    }
    
    private enum LayoutItem: String {
        case item = "Item"
        case header = "UICollectionElementKindSectionHeader"
        case footer = "UICollectionElementKindSectionFooter"
    }
    private var cache = [LayoutItem: [IndexPath: UICollectionViewLayoutAttributes]]()
    private func prepareCache() {
        cache.removeAll()
        
        cache[.item] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.header] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.footer] = [IndexPath: UICollectionViewLayoutAttributes]()
    }
    
    private var numberOfItems: Int {
        return collectionView?.numberOfItems(inSection: 0) ?? 0
    }
    
    private var collectionViewSize: CGSize {
        return collectionView?.frame.size ?? .zero
    }
    
    private func itemSize(with layoutMetrics: LayoutMetrics) -> CGSize {
        let size: CGSize
        switch layoutMetrics {
        case .compact:
            size = CGSize(width: LayoutConstants.compactHeight * 1.333, height: LayoutConstants.compactHeight)
        case .prominent:
            size = CGSize(width: LayoutConstants.prominentHeight * 1.2, height: LayoutConstants.prominentHeight)
        }
        return size
    }
    
    private var minimumSpacing: CGFloat = 1
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPosition: CGPoint = CGPoint(x: padding, y: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize(with: layoutMetrics))
            itemPosition.x += itemSize(with: layoutMetrics).width + minimumSpacing
            
            cache[.item]?[indexPath] = attributes
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.item]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache[.item]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    private var contentSize: CGSize {
        let contentsWidth = (CGFloat(numberOfItems) * itemSize(with: layoutMetrics).width) + (CGFloat(numberOfItems - 1) * minimumSpacing)
        return CGSize(width: contentsWidth, height: itemSize(with: layoutMetrics).height)
    }
    
    private var padding: CGFloat {
        return max(0, (collectionViewSize.width - contentSize.width) / 2)
    }
    
    override var collectionViewContentSize: CGSize {
        let contentSize = self.contentSize
        return CGSize(width: contentSize.width + padding * 2, height: contentSize.height)
    }
}

// MARK: -

internal class AppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak private var selectedStateView: RoundedView!
    
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appIconView: RoundedView!
    @IBOutlet weak private var appIconImageView: UIImageView!
    
    @IBOutlet weak var appInfoView: UIView!
    @IBOutlet weak var appInfoViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var appStatusIconView: AppStatusIconView!
    @IBOutlet weak var appTitleLabel: UILabel!
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        if AppCollectionViewLayout.LayoutConstants.compactHeight == layoutAttributes.frame.height {
            appInfoViewHeightLayout.constant = 0
        }
        else {
            appInfoViewHeightLayout.constant = 20
        }
        
        let margin: CGFloat = 4
        let contentBounds = UIEdgeInsetsInsetRect(layoutAttributes.frame, UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin))
        
        appIconView.cornerRadius = ((contentBounds.height - margin * 2) - appInfoViewHeightLayout.constant) * 0.5
    }

    //32 x 24 (1x)
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
    
    func setApp(_ app: App.Type, at indexPath: IndexPath) {
        iconImage = app.info.icon?.asUIImage ?? R.image.blankAppIcon()
        appTitleLabel.text = app.info.displayName.localized
        
        let status = AppCenter.default.persistedStatus(for: app)
        appStatusIconView.backgroundColor = status.statusColor
//        .unsupported --> app is not supported PersistableApp, or app.phase == develop/beta mode
//        .released
//        .updated
//        .used
    }
}

extension AppPersistedStatus {
    var statusColor: UIColor {
        switch self {
        case .unsupported: return UIColor(red: 237/255.0, green: 160/255.0, blue: 83/255.0, alpha: 1.0)
        case .released, .updated: return UIColor(red: 35/255.0, green: 104/255.0, blue: 246/255.0, alpha: 1.0)
        default: return .clear
        }
    }
}

class AppStatusIconView: DesignableView {
    override func initialize() {
        super.initialize()
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(ovalIn: bounds).cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        layer.mask = maskLayer
    }
}

// MARK: -

internal class DockView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard
            let contentView = subviews.last,
            !isHidden,
            alpha > 0,
            isUserInteractionEnabled
        else {
            return nil
        }
        
        let convertedPoint = contentView.convert(point, from: self)
        if contentView.point(inside: convertedPoint, with: event) {
            return contentView.hitTest(convertedPoint, with:event)
        }
        else {
            return super.hitTest(point, with: event)
        }
    }
}

internal class DockCollectionView: UICollectionView {
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
