//
//  AppUICollectionView.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

class BAppUICollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    struct CollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?
    }
    
    private var items = [CollectionItem]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    init(items: [CollectionItem]) {
        self.init()
        
        initialize()
        
        self.items = items
        
        collectionView.reloadData()
    }
    
    override var tintColor: UIColor! {
        didSet {
            collectionView.tintColor = tintColor
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: bounds, collectionViewLayout: BAppUICollectionViewLayout())
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = false
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.scrollsToTop = false
        view.backgroundColor = UIColor.clear
        view.register(BAppUICollectionViewCell.self, forCellWithReuseIdentifier: "BAppUICollectionViewCell")
        return view
    }()
    
    private func initialize() {
        addSubview(collectionView)
        collectionView.fitConstraints(to: self)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BAppUICollectionViewCell", for: indexPath) as! BAppUICollectionViewCell
        cell.title = items[indexPath.item].title
        cell.image = items[indexPath.item].image
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        items[indexPath.item].action?()
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

class BAppUICollectionViewLayout: UICollectionViewLayout {
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
    
    lazy var itemSize: CGSize = CGSize(width: self.collectionView?.bounds.height ?? 0, height: self.collectionView?.bounds.height ?? 0)
    var minimumSpacing: CGFloat = 4
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPosition: CGPoint = CGPoint(x: padding, y: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize)
            itemPosition.x += itemSize.width + minimumSpacing
            
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
        let contentsWidth = (CGFloat(numberOfItems) * itemSize.width) + (CGFloat(numberOfItems - 1) * minimumSpacing)
        return CGSize(width: contentsWidth, height: itemSize.height)
    }
    
    private var padding: CGFloat {
        return max(0, (collectionViewSize.width - contentSize.width) / 2)
    }
    
    override var collectionViewContentSize: CGSize {
        let contentSize = self.contentSize
        return CGSize(width: contentSize.width + padding * 2, height: contentSize.height)
    }
}

class BAppUICollectionViewCell: CustomCollectionViewCell {
    @IBOutlet private weak var selectionView: RoundedView!
    @IBOutlet private  weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleLabelHeightLayout: NSLayoutConstraint!
    
    var title: String? {
        didSet {
            titleLabel.text = title
            layoutContents()
        }
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
            layoutContents()
        }
    }
    
    private func layoutContents() {
        titleLabelHeightLayout.constant = imageView.image == nil ? contentView.bounds.height : ((titleLabel.text?.count ?? 0) > 0 ? 24 : 0)
        titleLabel.layoutIfNeeded()
    }
    
    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.5 : 1
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectionView.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        title = nil
        image = nil
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        imageView.tintColor = tintColor
        titleLabel.textColor = tintColor
    }
}

class BAppUICollectionStackView: BAppUICollectionView {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
