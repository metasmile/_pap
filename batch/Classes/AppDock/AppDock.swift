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
//    var title = ""
//    var appIcon:BundleImageSourceable?
//    var run = {}
    var app: App.Type
}

// MARK: -

protocol AppDockViewDelegate {
    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem)
}

// MARK: -

class AppDockView: CustomView {
    @IBOutlet weak var backgroundView: UIToolbar!
    @IBOutlet weak var topAccessoryView: UIStackView!
    @IBOutlet weak var topAccessoryViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var appConfigView: UIStackView!
    @IBOutlet weak var appConfigViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var dockView: UIView!
    @IBOutlet weak var appCollectionView: UICollectionView!
    @IBOutlet weak var bottomAccessoryView: UIView!
    
    var delegate: AppDockViewDelegate?
    
    var items = [AppDockItem]() {
        didSet {
            reloadAppDock()
        }
    }
    
    override func initialize() {
        super.initialize()
        
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        appCollectionView.register(AppDockViewCell.self, forCellWithReuseIdentifier: "STAppDockViewCell")
    }
    
    func reloadAppDock() {
        appCollectionView.collectionViewLayout.prepare()
        appCollectionView.reloadData()
    }
    
    var barStyle: UIBarStyle = UIBarStyle.default {
        didSet {
            backgroundView.barStyle = barStyle
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: topAccessoryView.bounds.height + appConfigView.bounds.height + dockView.bounds.height + bottomAccessoryView.bounds.height)
    }
    
    func setAccessoryViewToTop(_ view: UIView?, animated: Bool = true) {
        guard !hasAccessoryView(view) else { return }
        removeAllAccessoryViewsOnTop(animated: animated)
        addAccessoryViewToTop(view, animated: animated)
    }
    
    func addAccessoryViewToTop(_ view: UIView?, animated: Bool = true) {
        guard !hasAccessoryView(view) else { return }
        if let view = view {
            topAccessoryView.insertArrangedSubview(view, at: 0)
        }
        
        layoutTopAccessoryView()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
    
    func removeAccessoryViewsOnTop(_ view: UIView, animated: Bool = true) {
        guard hasAccessoryView(view) else { return }
        
        topAccessoryView.removeArrangedSubview(view)
        
        layoutTopAccessoryView()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
    
    func removeAllAccessoryViewsOnTop(animated: Bool = true) {
        topAccessoryView.arrangedSubviews.forEach({ topAccessoryView.removeArrangedSubview($0) })
        
        layoutTopAccessoryView()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
    
    fileprivate func layoutTopAccessoryView() {
        topAccessoryViewHeightLayout.constant = topAccessoryView.arrangedSubviews.map({ max($0.bounds.height, 44) }).reduce(0, +)
        
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func hasAccessoryView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return topAccessoryView.arrangedSubviews.contains(view)
    }
    
    func setAppConfigView(_ view: UIView?, animated: Bool = true) {
        guard !hasAppConfigView(view) else { return }
        appConfigView.arrangedSubviews.forEach({ appConfigView.removeArrangedSubview($0) })
        addAppConfigView(view, animated: animated)
    }
    
    func removeAllAppConfigViews(animated: Bool = true) {
        appConfigView.arrangedSubviews.forEach({ appConfigView.removeArrangedSubview($0) })
        
        layoutAppConfigView()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
    
    func addAppConfigView(_ view: UIView?, animated: Bool = true) {
        guard !hasAppConfigView(view) else { return }
        if let view = view {
            appConfigView.insertArrangedSubview(view, at: 0)
        }
        
        layoutAppConfigView()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
    
    fileprivate func hasAppConfigView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return appConfigView.arrangedSubviews.contains(view)
    }
    
    fileprivate func layoutAppConfigView() {
        appConfigViewHeightLayout.constant = appConfigView.arrangedSubviews.map({ max($0.bounds.height, 44) }).reduce(0, +)
        
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
}

// MARK: -

extension AppDockView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STAppDockViewCell", for: indexPath) as! AppDockViewCell
        let iconImage = items[indexPath.item].app.info.icon?.asUIImage

        cell.appIconImageView.image = iconImage?.withRenderingMode(.alwaysTemplate)
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
        let squareSize = collectionView.bounds.height
        return CGSize(width: squareSize, height: squareSize)
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
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.collectionView(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt:section)
    }
}

// MARK: -

class AppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak var appContentView: UIView!
    @IBOutlet weak var appIconImageView: UIImageView!
}
