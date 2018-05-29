//
//  AppDockView.swift
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
import DefaultsKit

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
    var beginContentLayoutState: AppDockContentLayoutState = .neutralized
}

internal class AppDockVoidableLayoutConatraint: NSLayoutConstraint {
    override var constant: CGFloat {
        set {
            super.constant = max(0, newValue)
        }
        get {
            return super.constant
        }
    }
}

class AppDockView: CustomView {
    private struct DefaultPreferences{
        struct AppDockView {
            static let compactHeight: CGFloat = 44
        }

        struct DrawerView {
            static let compactDisabledHeight: CGFloat = 14
            static let compactHeight: CGFloat = 22
            static let topMargin: CGFloat = 5
            static let prominentHeight: CGFloat = 49
        }

        static let Accessory = AppDockContentPreferences(preferredHeight: 44)
        static let Control = AppDockContentPreferences(preferredHeight: 44)
    }

    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var drawerView: AppDockDrawerView!
    @IBOutlet weak private var drawerViewHeightLayout: AppDockVoidableLayoutConatraint!
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appContentViewHeightLayout: AppDockVoidableLayoutConatraint!

    @IBOutlet weak private var topAccessoryView: UIView!
    @IBOutlet weak private var controllerView: UIView!
    @IBOutlet weak private var controllerViewHeightLayout: AppDockVoidableLayoutConatraint!
    @IBOutlet weak private var dockView: DockView!
    @IBOutlet weak private var dockViewHeightLayout: AppDockVoidableLayoutConatraint!
    @IBOutlet weak private var appCollectionView: UICollectionView!
    @IBOutlet weak private var appCollectionViewHeightLayout: AppDockVoidableLayoutConatraint!
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
            updateBackgroundColors()
        }
    }
    
    private func updateBackgroundColors() {
        let color = hasAnyContentAsLayout ? (barStyle == .black ? UIColor(red:0.11, green:0.11, blue:0.11, alpha:1) : .white) : .clear
        backgroundView.backgroundColor = color
        drawerView.tintColor = color
        bottomAccessoryView.backgroundColor = color
    }

    override func initialize() {
        super.initialize()

        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        appCollectionView.contentInset.top = 0
        appCollectionView.contentInset.bottom = 0
        appCollectionView.register(AppDockViewCell.self, forCellWithReuseIdentifier: String(describing: AppDockViewCell.self))

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

    var contentLayoutState: AppDockContentLayoutState {
        set(newValue){
            // POLICY BEGIN:  --> this is locking point for resizing preview
//            if hasControllerPinned{
//                return
//            }
            // POLICY END
            Defaults.shared.appDockContentLayoutState = newValue.rawValue
            drawerView.isHandleOpened = newValue == .maximized
        }
        get {
            var state = controller == nil ? .minimized : AppDockContentLayoutState(rawValue: Defaults.shared.appDockContentLayoutState) ?? .neutralized

            // POLICY BEGIN:
            if hasControllerPinned{
                if hasAppAccessoryAsLayout{
                    if state == .maximized{
                        // maximized is allowed
                    }else{
                        state = .neutralized
                    }
                }else{
                    // always minimized at default
                    state = .minimized 
                }
            }
            // POLICY END
            drawerView.isHandleOpened = state == .maximized
            return state
        }
    }

    var isContentLayoutMaximized: Bool {
        return contentLayoutState == .maximized
    }

    private var shouldDrawerEnable: Bool {
        if hasAppContentAsLayout {
            let hasMultipleApps = items.count > 1
            if hasControllerPinned{
                return hasMultipleApps && hasAppAccessoryAsLayout
            }else{
                return hasMultipleApps && hasAppControllerAsLayout
            }
        }
        return false
    }

    @IBOutlet private weak var dimmedView: UIView!
    var disabled: Bool = false {
        didSet {
            self.isUserInteractionEnabled = !disabled
            
            UIView.transition(with: self.dimmedView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.dimmedView.isHidden = !self.disabled
            }, completion: nil)
        }
    }

    /*
        layout priority : controller > accessory
    */

    // AppDock Control
    var controller: AppDockContent? {
        didSet {
            if let view = controller?.view {
                // POLICY BEGIN:
                //   NO KEEP MAXIMIZED LAYOUT
                //   force layout changed to neutralized when previous layout state is not minimized
                if contentLayoutState != .minimized {
                    contentLayoutState = .neutralized
                }
                // POLICY END
                
                controller?.willSetContentView(view, dock: self)

                setControllerView(view, animated: true)

                DispatchQueue.main.async {
                    self.controller?.didSetContentView(view, dock:self)
                }
            }
            else {
                controller?.willRemoveContentView()
                removeAllControllerViews()
            }
            
            delegate?.appDockView(self, didOpenDrawer: contentLayoutState == .maximized)
        }
    }

    var hasControllerPinned:Bool{
        return controller?.preferences?.displayMode == .pinned
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

            if hasControllerPinned {
                view.translatesAutoresizingMaskIntoConstraints = false
                view.topAnchor.constraint(equalTo: controllerView.topAnchor).isActive = true
                view.leadingAnchor.constraint(equalTo: controllerView.leadingAnchor).isActive = true
                view.trailingAnchor.constraint(equalTo: controllerView.trailingAnchor).isActive = true
                view.heightAnchor.constraint(equalToConstant: controller?.preferences?.preferredHeight ?? 0).isActive = true
            }
            else {
                view.fitConstraints(to: controllerView)
            }
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
                accessory?.willSetContentView(view, dock: self)

                setTopAccessoryView(view, animated: true)

                DispatchQueue.main.async{
                    self.accessory?.didSetContentView(view, dock:self)
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

//AppDock
extension AppDockView: AppDock{
    func expandDockIfNeeded(reloadContents: Bool?=nil) {
        self.setDrawerDisplay(forState: .maximized, reloadDockContentViews: reloadContents)
    }

    func contractDockIfNeeded(reloadContents: Bool?=nil) {
        self.setDrawerDisplay(forState: .neutralized, reloadDockContentViews: reloadContents)
    }
}

extension AppDockView {
    fileprivate static var VoidLayoutValue:CGFloat {
        return -1
    }

    fileprivate var hasContentAsLayout: Bool {
        return hasAppContentAsLayout && preferredDockViewHeight != AppDockView.VoidLayoutValue
    }
    
    fileprivate var hasAnyContentAsLayout: Bool {
        return hasAppContentAsLayout || preferredDockViewHeight != AppDockView.VoidLayoutValue
    }

    fileprivate var hasAppControllerAsLayout: Bool{
        return preferredControllerViewHeight != AppDockView.VoidLayoutValue
    }

    fileprivate var hasAppAccessoryAsLayout: Bool{
        return preferredAccessoryViewHeight != AppDockView.VoidLayoutValue
    }

    fileprivate var hasAppContentAsLayout: Bool{
        return hasAppControllerAsLayout || hasAppAccessoryAsLayout
    }

    fileprivate var preferredAppContentViewHeight: CGFloat {
        return max(0, preferredAccessoryViewHeight) + max(0, preferredControllerViewHeight)
    }

    fileprivate var preferredDrawerViewHeight: CGFloat {
        if hasAppControllerAsLayout{
            return shouldDrawerEnable ? DefaultPreferences.DrawerView.compactHeight : DefaultPreferences.DrawerView.compactDisabledHeight
        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredDockViewHeight: CGFloat {
        return items.count > 1 ? DefaultPreferences.AppDockView.compactHeight : AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredAccessoryViewHeight: CGFloat {
        if let accessory = self.accessory{
            return accessory.preferences?.preferredHeight ?? DefaultPreferences.Accessory.preferredHeight
        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredControllerViewHeight: CGFloat {
        if let control = self.controller {
            return control.preferences?.preferredHeight ?? DefaultPreferences.Control.preferredHeight
        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredAppContentViewMaximumHeight: CGFloat {
        return ConstAppContentViewMaximumHeight
    }

    private var ConstAppContentViewMaximumHeight: CGFloat{
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

        drawerView.isBarHidden = !shouldDrawerEnable
        drawerView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutDockView() {
        dockViewHeightLayout.constant = preferredDockViewHeight

        let isDockViewAppearing = preferredDockViewHeight != AppDockView.VoidLayoutValue
        dockView.isHidden = !isDockViewAppearing
        
        dockView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func layoutAppContentViews() {
        switch contentLayoutState {
        case .minimized:
            drawerViewHeightLayout.constant = preferredDrawerViewHeight
            appContentViewHeightLayout.constant = preferredAccessoryViewHeight
            controllerViewHeightLayout.constant = 0
        case .maximized:
            drawerViewHeightLayout.constant = DefaultPreferences.DrawerView.prominentHeight
            appContentViewHeightLayout.constant = preferredAppContentViewMaximumHeight
            
            let contentLayoutConstant = appContentViewHeightLayout.constant
            let controllerLayoutConstant = (hasControllerPinned && contentLayoutState == .maximized) ? preferredControllerViewHeight : contentLayoutConstant - max(0, preferredAccessoryViewHeight)
            controllerViewHeightLayout.constant = controllerLayoutConstant
        case .neutralized:
            drawerViewHeightLayout.constant = preferredDrawerViewHeight
            appContentViewHeightLayout.constant = max(0, preferredControllerViewHeight) + max(0, preferredAccessoryViewHeight)
            controllerViewHeightLayout.constant = preferredControllerViewHeight
        }
        
        controllerView.layoutIfNeeded()
        
        drawerView.isBarHidden = !shouldDrawerEnable
        drawerView.layoutIfNeeded()
        
        updateBackgroundColors()
        
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.appDockViewCell.name, for: indexPath) as! AppDockViewCell
        cell.setAppInfo(items[indexPath.item].app, at: indexPath)

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

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !collectionView.isDecelerating
    }
}

extension AppDockView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldDrawerEnable
    }
    
    @objc func drawerDidTap(sender: UITapGestureRecognizer) {
        guard self.gestureRecognizerShouldBegin(sender) else{
            //INFO: gestureRecognizerShouldBegin == false, but drawerDidTap was called.
            return
        }
        
        switch contentLayoutState {
        case .maximized: setDrawerDisplay(forState:.neutralized)
        case .neutralized: setDrawerDisplay(forState:.maximized)
        case .minimized: setDrawerDisplay(forState:.neutralized)
        }
    }
    
    @objc func gestureDidRecognize(sender: AppDockGestureRecognizer) {
        let translation = sender.translation(in: self)
        let velocity = sender.velocity(in: self)

        switch sender.state {
        case .began:
            sender.beginDrawerOffset = drawerViewHeightLayout.constant
            sender.beginAppContentViewOffset = appContentViewHeightLayout.constant
            sender.beginContentLayoutState = contentLayoutState
            break
        case .changed:
            let delta = sender.beginDrawerOffset - translation.y
            let maxHeight = max(DefaultPreferences.DrawerView.compactHeight, DefaultPreferences.DrawerView.prominentHeight)
            let minHeight = min(DefaultPreferences.DrawerView.compactHeight, DefaultPreferences.DrawerView.prominentHeight)
            
            let appContentViewHeight: CGFloat = {
                //https://medium.com/thoughts-on-thoughts/recreating-apple-s-rubber-band-effect-in-swift-dbf981b40f35
                func logConstraintValueForYPoisition(_ yPosition: CGFloat, limitation: CGFloat) -> CGFloat {
                    return limitation * (1 + log10(yPosition/limitation))
                }
                let offset = sender.beginAppContentViewOffset - translation.y
                return isContentLayoutMaximized || (hasControllerPinned && contentLayoutState != .minimized && !hasAppAccessoryAsLayout) ? logConstraintValueForYPoisition(offset, limitation: sender.beginAppContentViewOffset) : offset
            }()

            appContentViewHeightLayout.constant = max(preferredAccessoryViewHeight, appContentViewHeight)
            controllerViewHeightLayout.constant = (hasControllerPinned && contentLayoutState != .minimized) ? preferredControllerViewHeight : appContentViewHeightLayout.constant - max(0, preferredAccessoryViewHeight)
            
            if contentLayoutState == .maximized {
                drawerView.handleOpeningProgress = remapNormalizeClamp(delta, minHeight, maxHeight)
                topAccessoryView.layoutIfNeeded()
                controllerView.layoutIfNeeded()
            } else if contentLayoutState == .neutralized {
                drawerViewHeightLayout.constant = min(DefaultPreferences.DrawerView.prominentHeight, max(DefaultPreferences.DrawerView.compactHeight, delta))
            }
            
            if hasControllerPinned && (contentLayoutState == .maximized || sender.beginContentLayoutState == .neutralized) {
                let draggingRatio = (translation.y / sender.beginAppContentViewOffset) * 0.5
                let scale = max(1 - draggingRatio, 1)
                topAccessoryView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            
            if !hasControllerPinned {
                appContentView.layoutIfNeeded()
            }
            
            invalidateIntrinsicContentSize()
            
            if contentLayoutState != .minimized && sender.beginDrawerOffset - translation.y < 0 {
                closeDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
            else if contentLayoutState != .maximized && sender.beginDrawerOffset - translation.y > DefaultPreferences.DrawerView.prominentHeight * 2 {
                openDrawer()
                sender.isEnabled = false
                sender.isEnabled = true
            }
        default:
            if sender.beginContentLayoutState == contentLayoutState && velocity.y < 0 {
                openDrawer()
            }
            else if sender.beginContentLayoutState == contentLayoutState && velocity.y > 0 {
                closeDrawer()
            }
            else {
                reloadKeepingDrawerOpened()
            }
        }
    }
    
    func reloadKeepingDrawerOpened() {
        setDrawerDisplay(forState:contentLayoutState, reloadDockContentViews: true)
    }
    
    func closeDrawer(reloadDockContentViews: Bool? = nil) {
        switch contentLayoutState {
            case .maximized:
                contentLayoutState = .neutralized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: reloadDockContentViews)
            case .neutralized:
                contentLayoutState = .minimized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: reloadDockContentViews)
            case .minimized:
                return
        }
    }
    
    func openDrawer(reloadDockContentViews: Bool? = nil) {
        switch contentLayoutState {
            case .maximized:
                return
            case .neutralized:
                contentLayoutState = .maximized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: nil)
            case .minimized:
                contentLayoutState = .neutralized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: nil)
        }
    }
    
    func setDrawerDisplay(forState state: AppDockContentLayoutState, reloadDockContentViews: Bool? = nil) {
        switch state {
            case .minimized:
                minimizeDrawer(reloadDockContentViews: reloadDockContentViews)

            case .neutralized:
                neutralizeDrawer(reloadDockContentViews: reloadDockContentViews)

            case .maximized:
                maximizeDrawer(reloadDockContentViews: reloadDockContentViews)
        }
    }

    private func maximizeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? (contentLayoutState != .maximized)

        UIView.animateAsSpring(animations: {
            self.topAccessoryView.transform = .identity
        })
        
        contentLayoutState = .maximized
        drawerView.isBarHidden = !shouldDrawerEnable
        drawerViewHeightLayout.constant = DefaultPreferences.DrawerView.prominentHeight

        appContentViewHeightLayout.constant = preferredAppContentViewMaximumHeight
        
        let contentLayoutConstant = appContentViewHeightLayout.constant
        let controllerLayoutConstant = (hasControllerPinned && contentLayoutState == .maximized) ? preferredControllerViewHeight : contentLayoutConstant - max(0, preferredAccessoryViewHeight)
        let accessoryLayoutConstant = (hasControllerPinned && contentLayoutState == .maximized) ? contentLayoutConstant - max(0, preferredControllerViewHeight) : preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = controllerLayoutConstant
        
        if !hasControllerPinned {
            appContentView.layoutIfNeeded()
        }
        
        invalidateIntrinsicContentSize()

        controller?.delegate?.dockWillExpand(self)
        accessory?.delegate?.dockWillExpand(self)

        animateAsSpringSuperviewLayoutIfNeeded { _ in

            self.controller?.delegate?.dockDidExpand(self)
            self.accessory?.delegate?.dockDidExpand(self)
        }

        if reloadDockContentViews {
            (accessory?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: accessoryLayoutConstant))

            (controller?.view as? AppDockContentView)?.reloadContentThatFits(size:CGSize(width: UIViewNoIntrinsicMetric, height: controllerLayoutConstant))
        }
        
        delegate?.appDockView(self, didOpenDrawer: true)
    }

    private func neutralizeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? (contentLayoutState != .neutralized)

        UIView.animateAsSpring(animations: {
            self.topAccessoryView.transform = .identity
        })
        
        contentLayoutState = .neutralized
        drawerView.isBarHidden = !shouldDrawerEnable
        drawerViewHeightLayout.constant = preferredDrawerViewHeight

        appContentViewHeightLayout.constant = max(0, preferredControllerViewHeight) + max(0, preferredAccessoryViewHeight)
        controllerViewHeightLayout.constant = preferredControllerViewHeight
        
        if !hasControllerPinned {
            appContentView.layoutIfNeeded()
        }
        
        invalidateIntrinsicContentSize()

        controller?.delegate?.dockWillContract(self)
        accessory?.delegate?.dockWillContract(self)

        animateAsSpringSuperviewLayoutIfNeeded { _ in
            self.controller?.delegate?.dockDidContract(self)
            self.accessory?.delegate?.dockDidContract(self)
        }

        if reloadDockContentViews {
            (accessory?.view as? AppDockContentView)?.reloadContent()

            (controller?.view as? AppDockContentView)?.reloadContent()
        }
        
        delegate?.appDockView(self, didOpenDrawer: false)
    }
    
    private func minimizeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? (contentLayoutState != .minimized)
        
        UIView.animateAsSpring(animations: {
            self.topAccessoryView.transform = .identity
        })
        
        contentLayoutState = .minimized
        drawerView.isBarHidden = !shouldDrawerEnable
        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        
        appContentViewHeightLayout.constant = preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = 0
        
        if !hasControllerPinned {
            appContentView.layoutIfNeeded()
        }
        
        invalidateIntrinsicContentSize()
        
        controller?.delegate?.dockWillContract(self)
        accessory?.delegate?.dockWillContract(self)
        
        animateAsSpringSuperviewLayoutIfNeeded { _ in
            self.controller?.delegate?.dockDidContract(self)
            self.accessory?.delegate?.dockDidContract(self)
        }
        
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
        guard let fromLayout = appCollectionView.collectionViewLayout as? AppCollectionViewLayout, fromLayout.layoutMetrics == .compact else { return }
        
        let toLayout = AppCollectionViewLayout(layoutMetrics: .prominent)
        
        let visibleItemCount = appCollectionView.indexPathsForVisibleItems.count
        let touchRatio = appCollectionView.panGestureRecognizer.location(in: self).x / appCollectionView.bounds.width
        let index = Int(CGFloat(visibleItemCount - 1) * touchRatio)
        
        let targetIndexPath = visibleItemCount > 0 ? appCollectionView.indexPathsForVisibleItems.sorted()[index] : nil
        
        appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.prominentHeight
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.appCollectionView.superview?.layoutIfNeeded()
            self.appCollectionView.setCollectionViewLayout(toLayout, animated: false)
            
            if let indexPath = targetIndexPath {
                self.appCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }, completion: nil)
    }
    
    func zoomOutAppCollectionView(delay: Double = 1.5) {
        guard (appCollectionView.collectionViewLayout as? AppCollectionViewLayout)?.layoutMetrics == .prominent else { return }
        
        let timerId = "app_dock_bar_magnifying_timer"
        Timer.getScheduledTimer(identifier: timerId)?.invalidate()
        Timer.scheduledTimer(identifier: timerId, withTimeInterval: delay, repeats: false) { timer in
            self.showAppCollectionZoomOutAnimation()
        }
    }
    
    private func showAppCollectionZoomOutAnimation() {
        let toLayout = AppCollectionViewLayout(layoutMetrics: .compact)
        
        let visibleItemCount = appCollectionView.indexPathsForVisibleItems.count
        let targetIndexPath = visibleItemCount > 0 ? appCollectionView.indexPathsForVisibleItems.sorted()[visibleItemCount / 2] : nil
        
        self.appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.compactHeight
        UIView.animateAsSpring(0.4, delay: 0, animations: {
            self.appCollectionView.superview?.layoutIfNeeded()
            self.appCollectionView.setCollectionViewLayout(toLayout, animated: false)
            
            if let indexPath = targetIndexPath {
                self.appCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }, completion: nil)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.isTracking, scrollView.isDragging {
            zoomInAppCollectionView()
        }
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
    
    init(layoutMetrics: LayoutMetrics = .compact) {
        super.init()
        self.layoutMetrics = layoutMetrics
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
            size = CGSize(width: LayoutConstants.prominentHeight * 1.1, height: LayoutConstants.prominentHeight)
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
    
    var contentSize: CGSize {
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

    //persistedStatus display will be maintained on runtime.
    private static var persistedStatusDict = [String:AppPersistedStatus]()

    func setAppInfo(_ app: App.Type, at indexPath: IndexPath) {
        iconImage = app.info.icon?.asUIImage ?? R.image.blankAppIcon()
        appTitleLabel.text = app.info.displayName.localized

        var status = AppDockViewCell.persistedStatusDict[app.info.identifier]
        if status == nil{
            status = AppCenter.default.persistedStatus(for: app)
            AppDockViewCell.persistedStatusDict[app.info.identifier] = status
        }
        appStatusIconView.backgroundColor = status?.statusColor
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

internal class DockCollectionBackgroundView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setLineWidth(0.5)
        ctx?.setFillColor(UIColor(red: 246 / 255.0, green: 246 / 255.0, blue: 246 / 255.0, alpha: 1).cgColor)
        ctx?.setStrokeColor(UIColor(red: 204 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1).cgColor)
        ctx?.move(to: .zero)
        ctx?.addLine(to: CGPoint(x: rect.width, y: 0))
        ctx?.move(to: CGPoint(x: 0, y: rect.height))
        ctx?.addLine(to: CGPoint(x: rect.width, y: rect.height))
        ctx?.strokePath()
    }
}
