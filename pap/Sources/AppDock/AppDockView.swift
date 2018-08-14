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

protocol AppDockViewDataSource {
    func numberOfSections(in view: AppDockView) -> Int
    func appDockView(_ view: AppDockView, numbefOfItemsInSection section: Int) -> Int
    func appDockView(_ view: AppDockView, itemAt indexPath: IndexPath) -> AppDockItem?
    func content(in view: AppDockView) -> AppDockContent?
}

protocol AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem)
    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool)
    func appDockView(_ view: AppDockView, needsScrollToBottom: Bool)
}

class AppDockGestureRecognizer: UIPanGestureRecognizer {
    var beginDrawerOffset: CGFloat = 0
    var beginAppContentViewOffset: CGFloat = 0
    var beginContentLayoutState: AppDockContentLayoutState = .neutralized
}

protocol AppDockContentTransition {
    func transitionWillBegin(at location: CGPoint)
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
            static let compactDisabledTopMargin = prominentHeight - compactDisabledHeight

            static let compactHeight: CGFloat = 22
            static let compactTopMargin = prominentHeight - compactHeight

            static let topMargin: CGFloat = 5
            static let prominentHeight: CGFloat = 49
        }

        static let Accessory = AppDockContentPreferences(preferredHeight: 44)
        static let Control = AppDockContentPreferences(preferredHeight: 44)

        static let ControlMaxPreferredHeight:CGFloat = UIScreen.main.bounds.height/3
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
    var dataSource: AppDockViewDataSource?
    
    private var reorderAppGesture: UILongPressGestureRecognizer?
    
    func reloadData() {
        layoutDockView()
        
        reloadAppDock()
    }

    var barStyle: UIBarStyle = UIBarStyle.default {
        didSet {
            updateBackgroundColors()
        }
    }
    
    private func updateBackgroundColors() {
        let color = hasAnyContentAsLayout ? (barStyle == .black ? UIColor(red:0.11, green:0.11, blue:0.11, alpha:1) : .white) : .clear
        backgroundView.backgroundColor = color
        topAccessoryView.backgroundColor = color
        controllerView.backgroundColor = color
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
        appCollectionView.register(AppDockViewGroupSeparator.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: String(describing: AppDockViewGroupSeparator.self))

        drawerView.topMargin = DefaultPreferences.DrawerView.topMargin

        let gesture = AppDockGestureRecognizer(target: self, action: #selector(self.gestureDidRecognize))
        gesture.delegate = self
        addGestureRecognizer(gesture)
        
        //TODO: save order states
//        let longPressToDnD = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressDidRecognize))
//        appCollectionView.addGestureRecognizer(longPressToDnD)
//
//        reorderAppGesture = longPressToDnD
//        reorderAppGesture?.isEnabled = false

        let tapDrawerGesture = UITapGestureRecognizer(target: self, action: #selector(self.drawerDidTap))
        drawerView.addGestureRecognizer(tapDrawerGesture)
    }

    private func reloadAppDock() {
        appCollectionView.reloadData()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: drawerViewHeightLayout.constant + appContentViewHeightLayout.constant + dockViewHeightLayout.constant + bottomAccesoryViewSafeHeight)
    }

    private var bottomAccesoryViewSafeHeight: CGFloat{
        return max(self.bottomAccessoryView.bounds.height, UIViewController.root?.safeAreaInsets.bottom ?? 0) //self.safeAreaInsets is lazy
    }

    private var _contentLayoutState: AppDockContentLayoutState = .neutralized

    var contentLayoutState: AppDockContentLayoutState {
        set(newValue){
            _contentLayoutState = newValue
            drawerView.isHandleOpened = newValue == .maximized

            var committingLayoutState:AppDockContentLayoutState? = newValue

            if controller == nil{
                committingLayoutState = nil
            }

            // POLICY BEGIN:
            else if isNeedingFixedContentLayout {
                committingLayoutState = nil
            }
            // POLICY END

            if let state = committingLayoutState {
                //commit state when !isNeedingFixedContentLayout
                Defaults.shared.appDockContentLayoutState = state.rawValue
            }
        }
        get {

            // app does not provide/support appDockContent
            if controller == nil{
                _contentLayoutState = .minimized
            }

            // POLICY BEGIN:
            // app supports previewable
            else if isNeedingFixedContentLayout {
                if _contentLayoutState == .maximized { //INFO: this is different with "state == .maximized && !hasAppAccessoryAsLayout"
                    if !hasAppAccessoryAsLayout {
                        _contentLayoutState = .neutralized // force: .maximized -> .neutralized
                    }
                }
                else if _contentLayoutState == .minimized {
                    _contentLayoutState = .neutralized // force: .minimized -> .neutralized
                }
            }
            // POLICY END
            // default: apps support appDockContent
            else{
                _contentLayoutState = AppDockContentLayoutState(rawValue: Defaults.shared.appDockContentLayoutState) ?? _contentLayoutState
            }

            //render
            drawerView.isHandleOpened = _contentLayoutState == .maximized
            return _contentLayoutState
        }
    }

    var isContentLayoutMaximized: Bool {
        return contentLayoutState == .maximized
    }

    private var shouldDrawerBarEnable: Bool {
        if !hasAppContentAsLayout || dataSource?.numberOfSections(in: self) == 0 {
            return false
        }

        if isNeedingFixedContentLayout {
            return hasAppAccessoryAsLayout
        }else{
            return hasAppControllerAsLayout
        }
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
    
    func loadControllerContentIfNeeded(){
        let controller = dataSource?.content(in: self)
        if self.controller?.view != controller?.view{
            self.controller = controller
        }
    }

    /*
        layout priority : controller > accessory
    */

    // AppDock Control
    private var controller: AppDockContent? {
        willSet {
            controller?.willRemoveContentView()
        }
        
        didSet {
            if let view = controller?.view {
                controller?.willSetContentView(view, dock: self)

                setControllerView(view, animated: false)

//                DispatchQueue.main.async { //TODO: if not found any side-effect, remove async block
                    self.controller?.didSetContentView(view, dock:self)
//                }
            }
            else {
                controller?.willRemoveContentView()
                removeAllControllerViews(animated: false)
            }
            
            //INFO: no controller animation
            appContentView.layoutIfNeeded()
            
            delegate?.appDockView(self, didOpenDrawer: controller != nil && contentLayoutState == .maximized)
        }
    }

    var isNeedingFixedContentLayout:Bool{
        return (AppCenter.default.current as? AppDockApp.Type)?.fixedContentLayout ?? false
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

            if isNeedingFixedContentLayout {
                view.translatesAutoresizingMaskIntoConstraints = false
                view.topAnchor.constraint(equalTo: controllerView.topAnchor).isActive = true
                view.leadingAnchor.constraint(equalTo: controllerView.leadingAnchor).isActive = true
                view.trailingAnchor.constraint(equalTo: controllerView.trailingAnchor).isActive = true
                view.heightAnchor.constraint(equalToConstant: preferredControllerViewHeight).isActive = true
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
        willSet {
            accessory?.willRemoveContentView()
        }
        
        didSet {
            if let view = accessory?.view {
                accessory?.willSetContentView(view, dock: self)

                setTopAccessoryView(view, animated: true)

//                DispatchQueue.main.async{ //TODO: if not found any side-effect, remove async block
                self.accessory?.didSetContentView(view, dock:self)
//                }
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
            return shouldDrawerBarEnable ? DefaultPreferences.DrawerView.compactHeight : DefaultPreferences.DrawerView.compactDisabledHeight
        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredDockViewHeight: CGFloat {
        return dataSource?.numberOfSections(in: self) ?? 0 > 1 ? DefaultPreferences.AppDockView.compactHeight : AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredAccessoryViewHeight: CGFloat {
        if let accessory = self.accessory{
            return accessory.preferences?.preferredHeight ?? DefaultPreferences.Accessory.preferredHeight
        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredControllerViewHeight: CGFloat {
        if let control = self.controller {
            let preferredHeight = control.preferences?.preferredHeight ?? DefaultPreferences.Control.preferredHeight

            if preferredHeight == AppDockContentPreferences.GreatestHeight{
                if isNeedingFixedContentLayout {
                    return min(preferredHeight, preferredAppContentViewMaximumHeight + DefaultPreferences.DrawerView.compactDisabledTopMargin)
                }else{

                    return min(preferredHeight, preferredAppContentViewMaximumHeight - DefaultPreferences.DrawerView.topMargin*2)
                }
            }else{
                return min(preferredHeight,DefaultPreferences.ControlMaxPreferredHeight)
            }

        }
        return AppDockView.VoidLayoutValue
    }
    
    fileprivate var preferredAppContentViewMaximumHeight: CGFloat {
        let topOffset = DefaultPreferences.DrawerView.prominentHeight + DefaultPreferences.AppDockView.compactHeight + bottomAccesoryViewSafeHeight

        if let rvc = UIViewController.root{
            return (rvc.view.bounds.height - rvc.safeAreaInsets.top - rvc.additionalSafeAreaInsets.top) - topOffset
        }

        if let h = self.superview?.bounds.height{
            return h - topOffset
        }

        assert(false, "not found superview and rootViewController 🤔")
        return UIScreen.main.bounds.height - topOffset
    }
    
    fileprivate func layoutDrawerView() {
        drawerViewHeightLayout.constant = preferredDrawerViewHeight

        drawerView.isBarHidden = !shouldDrawerBarEnable
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
            let controllerLayoutConstant = isNeedingFixedContentLayout ? preferredControllerViewHeight : contentLayoutConstant - max(0, preferredAccessoryViewHeight)
            controllerViewHeightLayout.constant = controllerLayoutConstant
        case .neutralized:
            drawerViewHeightLayout.constant = preferredDrawerViewHeight
            appContentViewHeightLayout.constant = max(0, preferredControllerViewHeight) + max(0, preferredAccessoryViewHeight)
            controllerViewHeightLayout.constant = preferredControllerViewHeight
        }
        
        drawerView.isBarHidden = !shouldDrawerBarEnable
        drawerView.layoutIfNeeded()
        
        updateBackgroundColors()
        
        invalidateIntrinsicContentSize()
    }
}

extension AppDockView {

    var selectedIndexPath: IndexPath? {
        return appCollectionView.indexPathsForSelectedItems?.first
    }
    
    func selectItem(at indexPath: IndexPath, animated: Bool = false) {
        guard indexPath.item < dataSource?.appDockView(self, numbefOfItemsInSection: indexPath.section) ?? 0 else { return }
        appCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        zoomOutAppCollectionView(delay: 0)
        
        if let item = dataSource?.appDockView(self, itemAt: indexPath) {
            delegate?.appDockView(self, didSelectItemWith: item)
        }
    }
}

// MARK: -

extension AppDockView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections(in: self) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.appDockView(self, numbefOfItemsInSection: section) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.appDockViewCell.name, for: indexPath) as! AppDockViewCell
        
        if let item = dataSource?.appDockView(self, itemAt: indexPath) {
            cell.setAppInfo(item.app, at: indexPath)
        }

        switch barStyle {
        case .black:
            cell.iconViewTintColor = .white
        default:
            cell.iconViewTintColor = .black
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: AppDockViewGroupSeparator.self), for: indexPath)
        return view
    }
}

extension AppDockView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        zoomOutAppCollectionView(delay: 0)

        UISelectionFeedbackGenerator().selectionChanged()
        
        if let item = dataSource?.appDockView(self, itemAt: indexPath) {
            delegate?.appDockView(self, didSelectItemWith: item)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if !collectionView.isDecelerating && !collectionView.isBouncing {
            delegate?.appDockView(self, needsScrollToBottom: collectionView.indexPathsForSelectedItems?.contains(indexPath) == true)
            return true
        }
        else {
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return reorderAppGesture != nil
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        items.swapAt(sourceIndexPath.item, destinationIndexPath.item)
    }
}

extension UIScrollView {
    var isBouncing: Bool {
        return isBouncingTop || isBouncingLeft || isBouncingBottom || isBouncingRight
    }
    var isBouncingTop: Bool {
        return contentOffset.y < -contentInset.top
    }
    var isBouncingLeft: Bool {
        return contentOffset.x < -contentInset.left
    }
    var isBouncingBottom: Bool {
        let contentFillsScrollEdges = floor(contentSize.height + contentInset.top + contentInset.bottom) >= floor(bounds.height)
        return contentFillsScrollEdges && floor(contentOffset.y) > floor(contentSize.height - bounds.height + contentInset.bottom)
    }
    var isBouncingRight: Bool {
        let contentFillsScrollEdges = floor(contentSize.width + contentInset.left + contentInset.right) >= floor(bounds.width)
        return contentFillsScrollEdges && floor(contentOffset.x) > floor(contentSize.width - bounds.width + contentInset.right)
    }
}

extension AppDockView {
    @objc func longPressDidRecognize(sender: UILongPressGestureRecognizer) {
        switch(sender.state) {
            case .began:
                guard let selectedIndexPath = appCollectionView.indexPathForItem(at: sender.location(in: appCollectionView)) else { break }
                appCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            case .changed:
                appCollectionView.updateInteractiveMovementTargetPosition(sender.location(in: appCollectionView))
            case .ended:
                appCollectionView.endInteractiveMovement()
                zoomOutAppCollectionView(delay: 0.5)
            default:
                appCollectionView.cancelInteractiveMovement()
                zoomOutAppCollectionView(delay: 0.5)
        }
    }
}

extension AppDockView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is AppDockGestureRecognizer {
            return shouldDrawerBarEnable
        }
        else if gestureRecognizer == reorderAppGesture {
            return true
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
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
            
            if let content =  accessory?.view as? AppDockContentTransition {
                content.transitionWillBegin(at: sender.location(in: accessory?.view))
            }
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
                return isContentLayoutMaximized || (isNeedingFixedContentLayout && contentLayoutState != .minimized && !hasAppAccessoryAsLayout) ? logConstraintValueForYPoisition(offset, limitation: sender.beginAppContentViewOffset) : offset
            }()

            appContentViewHeightLayout.constant = max(preferredAccessoryViewHeight, appContentViewHeight)
            controllerViewHeightLayout.constant = (isNeedingFixedContentLayout && contentLayoutState != .minimized) ? preferredControllerViewHeight : appContentViewHeightLayout.constant - max(0, preferredAccessoryViewHeight)
            
            if contentLayoutState == .maximized {
                drawerView.handleOpeningProgress = remapNormalizeClamp(delta, minHeight, maxHeight)
                topAccessoryView.layoutIfNeeded()
                controllerView.layoutIfNeeded()
            } else if contentLayoutState == .neutralized {
                drawerViewHeightLayout.constant = min(DefaultPreferences.DrawerView.prominentHeight, max(DefaultPreferences.DrawerView.compactHeight, delta))
            }
            
            if isNeedingFixedContentLayout && (contentLayoutState == .maximized || sender.beginContentLayoutState == .neutralized) {
                let draggingRatio = (translation.y / sender.beginAppContentViewOffset) * 0.5
                let scale = max(1 - draggingRatio, 1)
                topAccessoryView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            
            invalidateIntrinsicContentSize()
            
            if contentLayoutState != .minimized && sender.beginDrawerOffset - translation.y < 0 {
                closeDrawer()

                if contentLayoutState == .minimized{
                    papLog.app.minimizeAppDockDrawer()
                }

                sender.isEnabled = false
                sender.isEnabled = true
            }
            else if contentLayoutState != .maximized && sender.beginDrawerOffset - translation.y > DefaultPreferences.DrawerView.prominentHeight * 2 {
                openDrawer()

                if contentLayoutState == .maximized{
                    papLog.app.maximizeAppDockDrawer()
                }

                sender.isEnabled = false
                sender.isEnabled = true
            }
        default:
            if sender.beginContentLayoutState == contentLayoutState && velocity.y < 0 {
                openDrawer(reloadDockContentViews: true)
            }
            else if sender.beginContentLayoutState == contentLayoutState && velocity.y > 0 {
                closeDrawer(reloadDockContentViews: true)
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
                contentLayoutState = .maximized
                setDrawerDisplay(forState: contentLayoutState) //INFO: prevent stuck drawer on top of the screen
            case .neutralized:
                contentLayoutState = .maximized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: reloadDockContentViews)
            case .minimized:
                contentLayoutState = .neutralized
                setDrawerDisplay(forState: contentLayoutState, reloadDockContentViews: reloadDockContentViews)
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
    
    var shouldMaximizeDrawer: Bool {
        return !(isNeedingFixedContentLayout && !hasAppAccessoryAsLayout)
    }

    private func maximizeDrawer(reloadDockContentViews: Bool? = nil) {
        guard shouldMaximizeDrawer else {
            setDrawerDisplay(forState: .neutralized, reloadDockContentViews: true)
            return
        }
        let reloadDockContentViews = reloadDockContentViews ?? (contentLayoutState != .maximized)

        UIView.animateAsSpring(animations: {
            self.topAccessoryView.transform = .identity
        })
        
        contentLayoutState = .maximized
        drawerView.isBarHidden = !shouldDrawerBarEnable
        drawerViewHeightLayout.constant = DefaultPreferences.DrawerView.prominentHeight

        appContentViewHeightLayout.constant = preferredAppContentViewMaximumHeight
        
        let contentLayoutConstant = appContentViewHeightLayout.constant
        let controllerLayoutConstant = isNeedingFixedContentLayout ? preferredControllerViewHeight : contentLayoutConstant - max(0, preferredAccessoryViewHeight)
        let accessoryLayoutConstant = isNeedingFixedContentLayout ? contentLayoutConstant - max(0, preferredControllerViewHeight) : preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = controllerLayoutConstant
        
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
        drawerView.isBarHidden = !shouldDrawerBarEnable
        drawerViewHeightLayout.constant = preferredDrawerViewHeight

        appContentViewHeightLayout.constant = max(0, preferredControllerViewHeight) + max(0, preferredAccessoryViewHeight)
        controllerViewHeightLayout.constant = preferredControllerViewHeight
        
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
        
        let dimmedWithGreatestHeight = self.controller?.preferences?.preferredHeight == AppDockContentPreferences.GreatestHeight
        delegate?.appDockView(self, didOpenDrawer: dimmedWithGreatestHeight)
    }
    
    private func minimizeDrawer(reloadDockContentViews: Bool? = nil) {
        let reloadDockContentViews = reloadDockContentViews ?? (contentLayoutState != .minimized)
        
        UIView.animateAsSpring(animations: {
            self.topAccessoryView.transform = .identity
        })
        
        contentLayoutState = .minimized
        drawerView.isBarHidden = !shouldDrawerBarEnable
        drawerViewHeightLayout.constant = preferredDrawerViewHeight
        
        appContentViewHeightLayout.constant = preferredAccessoryViewHeight
        controllerViewHeightLayout.constant = 0
        
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

extension AppDockView {
    func zoomInAppCollectionView() {
        guard let fromLayout = appCollectionView.collectionViewLayout as? AppCollectionViewLayout, fromLayout.layoutMetrics == .compact else { return }
        
        let toLayout = AppCollectionViewLayout(layoutMetrics: .prominent)
        
        let touchLocation = appCollectionView.panGestureRecognizer.location(in: self.appCollectionView)
        let touchRatio = convert(touchLocation, from: appCollectionView).x / appCollectionView.bounds.width
        let targetIndexPath = appCollectionView.indexPathForItem(at: touchLocation)
        
        self.appCollectionView.setCollectionViewLayout(toLayout, animated: false)
        
        if let indexPath = targetIndexPath, let attributes = toLayout.layoutAttributesForItem(at: indexPath) {
            let offsetX = min(max(0, attributes.center.x - touchRatio * self.appCollectionView.bounds.width), toLayout.collectionViewContentSize.width - self.appContentView.bounds.width)
            let targetOffset = CGPoint(x: offsetX, y: self.appCollectionView.contentOffset.y)
            self.appCollectionView.setContentOffset(targetOffset, animated: false)
        }
        
        appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.prominentHeight
        
        self.appCollectionView.visibleCells.forEach {
            ($0 as? AppDockViewCell)?.showsInfoView = false
        }
        
        UIView.animateAsSpring(options: [.allowUserInteraction], animations: {
            self.dockView.layoutIfNeeded()
            self.appCollectionView.visibleCells.forEach {
                ($0 as? AppDockViewCell)?.showsInfoView = true
            }
        }, completion: nil)
        
        reorderAppGesture?.isEnabled = true
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
        guard reorderAppGesture?.state != .changed || reorderAppGesture?.state != .began else { return }
        
        let toLayout = AppCollectionViewLayout(layoutMetrics: .compact)
        
        self.appCollectionView.visibleCells.forEach {
            ($0 as? AppDockViewCell)?.showsInfoView = true
        }
        
        let selectedIndexPath = appCollectionView.indexPathsForSelectedItems?.first
        if let indexPath = selectedIndexPath {
            appCollectionView.deselectItem(at: indexPath, animated: false)
        }
        
        self.appCollectionViewHeightLayout.constant = AppCollectionViewLayout.LayoutConstants.compactHeight
        UIView.animateAsSpring(options: [.allowUserInteraction], animations: {
            self.appCollectionView.setCollectionViewLayout(toLayout, animated: false)
            self.dockView.layoutIfNeeded()
            
            self.appCollectionView.visibleCells.forEach {
                ($0 as? AppDockViewCell)?.showsInfoView = false
            }
            
            if let indexPath = selectedIndexPath {
                self.appCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        })
        
        reorderAppGesture?.isEnabled = false
    }
}

extension AppDockView: UIScrollViewDelegate {
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
    
    private var numberOfSections: Int {
        return collectionView?.numberOfSections ?? 0
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
    private var sectionSpacing: CGFloat {
        return layoutMetrics == .prominent ? 10 : 5
    }
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPosition: CGPoint = .zero
        
        for section in (0 ..< numberOfSections) {
            for indexPath in (0 ..< (collectionView?.numberOfItems(inSection: section) ?? 0)).map({ IndexPath(item: $0, section: section) }) {
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(origin: itemPosition, size: itemSize(with: layoutMetrics))
                itemPosition.x += itemSize(with: layoutMetrics).width + minimumSpacing
                
                cache[.item]?[indexPath] = attributes
            }
            
            if section < numberOfSections - 1 {
                //add section footer
                let indexPath = IndexPath(item: 0, section: section)
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: indexPath)
                let itemSize = self.itemSize(with: layoutMetrics)
                let footerSize = CGSize(width: 2, height: itemSize.height * (layoutMetrics == .prominent ? 0.7 : 0.6))
                
                itemPosition.x += sectionSpacing
                
                var footerPosition = itemPosition
                footerPosition.x -= footerSize.width / 2
                footerPosition.y += (itemSize.height - footerSize.height) / 2
                attributes.frame = CGRect(origin: footerPosition, size: footerSize)
                cache[.footer]?[indexPath] = attributes
                
                itemPosition.x += sectionSpacing
            }
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.item]?[indexPath]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.footer]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let items = cache[.item]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil }) ?? []
        let footers = cache[.footer]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil }) ?? []
        return items + footers
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    var contentSize: CGSize {
        var contentsWidth: CGFloat = 0
        for section in (0 ..< numberOfSections) {
            let numberOfItems = (collectionView?.numberOfItems(inSection: section) ?? 0)
            contentsWidth += (CGFloat(numberOfItems) * itemSize(with: layoutMetrics).width) + (CGFloat(numberOfItems - 1) * minimumSpacing) + sectionSpacing
        }
        
        return CGSize(width: contentsWidth, height: itemSize(with: layoutMetrics).height)
    }
    
    override var collectionViewContentSize: CGSize {
        let contentSize = self.contentSize
        return CGSize(width: contentSize.width, height: contentSize.height)
    }
}

// MARK: -

class AppIconRoundedView: RoundedView {
    override func initialize() {
        super.initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cornerRadius = bounds.height / 2
    }
}

internal class AppDockViewGroupSeparator: UICollectionReusableView {
    private lazy var seperateView: RoundedView = {
        let view = RoundedView(frame: .zero)
        view.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.5)
        view.cornerRadius = 1
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        addSubview(seperateView)
        seperateView.fitConstraints(to: self)
    }
}

internal class AppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak private var selectedStateView: RoundedView!
    
    @IBOutlet weak private var appContentView: UIView!
    @IBOutlet weak private var appIconView: AppIconRoundedView!
    @IBOutlet weak private var appIconViewWidthLayout: NSLayoutConstraint!
    @IBOutlet weak private var appIconViewTopLayout: NSLayoutConstraint!
    
    @IBOutlet weak private var appIconImageView: UIImageView!
    
    @IBOutlet weak var appInfoView: UIView!
    @IBOutlet weak var appInfoViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var appStatusIconView: AppStatusIconView!
    @IBOutlet weak var appTitleLabel: UILabel!
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        let iconBorderColor: UIColor
        if AppCollectionViewLayout.LayoutConstants.compactHeight == layoutAttributes.frame.height {
            showsInfoView = false
            
            appIconViewWidthLayout.constant = layoutAttributes.frame.width - 20
            appIconViewTopLayout.constant = 3.5
            
            iconBorderColor = UIColor(red: 218 / 255.0, green: 218 / 255.0, blue: 218 / 255.0, alpha: 1)
        }
        else {
            showsInfoView = true
            
            appIconViewWidthLayout.constant = layoutAttributes.frame.width - 26
            appIconViewTopLayout.constant = 4
            
            iconBorderColor = UIColor(red: 208 / 255.0, green: 208 / 255.0, blue: 208 / 255.0, alpha: 1)
        }
        
        appIconView.layer.borderColor = iconBorderColor.cgColor
        appIconView.layer.borderWidth = 1 / UIScreen.main.scale
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
    
    var showsInfoView: Bool = true {
        didSet {
            appInfoView.alpha = showsInfoView ? 1 : 0
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectedStateView.isHidden = !isSelected
        }
    }

    //persistedStatus display will be maintained on runtime.
    private static var persistedStatusDict = [String:AppPersistedStatus]()

    func setAppInfo(_ app: App.Type, at indexPath: IndexPath) {
        iconImage = app.info.iconBundleName?.asUIImage
        appTitleLabel.adjustsFontSizeToFitWidth = true
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
