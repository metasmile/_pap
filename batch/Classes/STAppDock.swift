//
//  STAppDock.swift
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
    var title = ""
    var appIcon: UIImage?
    var run = {}
}

// MARK: -

class STAppDockView: CustomView {
    @IBOutlet weak var backgroundView: UIToolbar!
    @IBOutlet weak var topAccessoryView: UIStackView!
    @IBOutlet weak var topAccessoryViewHeightLayout: NSLayoutConstraint!
    @IBOutlet weak var dockView: UIView!
    @IBOutlet weak var appCollectionView: UICollectionView!
    @IBOutlet weak var bottomAccessoryView: UIView!
    
    var items = [AppDockItem]() {
        didSet {
            reloadAppDock()
        }
    }
    
    override func initialize() {
        super.initialize()
        
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        appCollectionView.register(STAppDockViewCell.self, forCellWithReuseIdentifier: "STAppDockViewCell")
    }
    
    func reloadAppDock() {
        appCollectionView.collectionViewLayout.prepare()
        let contentWidth = appCollectionView.collectionViewLayout.collectionViewContentSize.width
        if contentWidth > appCollectionView.bounds.width {
            appCollectionView.contentInset.left = 0
            appCollectionView.contentInset.right = 0
        }
        else {
            let inset = (appCollectionView.bounds.width - contentWidth) / 2
            appCollectionView.contentInset.left = inset
            appCollectionView.contentInset.right = inset
        }
        
        appCollectionView.reloadData()
    }
    
    var barStyle: UIBarStyle = UIBarStyle.default {
        didSet {
            backgroundView.barStyle = barStyle
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: topAccessoryView.bounds.height + dockView.bounds.height + bottomAccessoryView.bounds.height)
    }
    
    func setAccessoryViewToTop(_ view: UIView?, animated: Bool = true) {
        _ = topAccessoryView.arrangedSubviews.map({ topAccessoryView.removeArrangedSubview($0) })
        addAccessoryViewToTop(view, animated: animated)
    }
    
    func addAccessoryViewToTop(_ view: UIView?, animated: Bool = true) {
        if let view = view {
            topAccessoryView.addArrangedSubview(view)
        }
        topAccessoryViewHeightLayout.constant = 44 * CGFloat(topAccessoryView.arrangedSubviews.count)
        
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.superview?.layoutIfNeeded()
            })
        }
    }
}

// MARK: -

extension STAppDockView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STAppDockViewCell", for: indexPath) as! STAppDockViewCell
        cell.appIconImageView.image = items[indexPath.item].appIcon?.withRenderingMode(.alwaysTemplate)
        switch barStyle {
        case .black:
            cell.appIconImageView.tintColor = .white
        default:
            cell.appIconImageView.tintColor = .black
        }
        return cell
    }
}

extension STAppDockView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        items[indexPath.item].run()
    }
}

extension STAppDockView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let squareSize = collectionView.bounds.height
        return CGSize(width: squareSize, height: squareSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

// MARK: -

class STAppDockViewCell: CustomCollectionViewCell {
    @IBOutlet weak var appContentView: UIView!
    @IBOutlet weak var appIconImageView: UIImageView!
}
