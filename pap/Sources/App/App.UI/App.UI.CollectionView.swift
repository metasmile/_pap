//
//  App.UI.CollectionView.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit


class AppUICollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    struct CollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?
    }
    
    private(set) var items = [CollectionItem]()
    
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

    func reloadData(items:[CollectionItem]?=nil){
        if let items = items{
            self.items = items
        }
        collectionView.reloadData()
    }
    
    override var tintColor: UIColor! {
        didSet {
            collectionView.tintColor = tintColor
        }
    }
    
    var cellSize: CGSize = .zero {
        didSet {
            (collectionView.collectionViewLayout as? AppUICollectionViewLayout)?.itemSize = cellSize
        }
    }
    var cellSpacing: CGFloat = 0 {
        didSet {
            collectionView.contentInset.left = cellSpacing
            collectionView.contentInset.right = cellSpacing
            
            (collectionView.collectionViewLayout as? AppUICollectionViewLayout)?.minimumSpacing = cellSpacing
        }
    }
    var cellImageInsets: UIEdgeInsets = .zero {
        didSet {
            (collectionView.collectionViewLayout as? AppUICollectionViewLayout)?.itemSize = cellSize
        }
    }
    
    private(set) lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: bounds, collectionViewLayout: AppUICollectionViewLayout())
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = false
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.scrollsToTop = false
        view.backgroundColor = UIColor.clear
        view.register(AppUICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: AppUICollectionViewCell.self))
        return view
    }()
    
    private func initialize() {
        addSubview(collectionView)
        collectionView.fitConstraints(to: self)
    }
    
    func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition = .centeredHorizontally) {
        DispatchQueue.main.async {
            self.collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.appUICollectionViewCell.name, for: indexPath) as! AppUICollectionViewCell
        cell.imageInsets = cellImageInsets
        cell.title = items[indexPath.item].title
        cell.image = items[indexPath.item].image
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        items[indexPath.item].action?()
        
        if collectionView.contentSize.width > collectionView.bounds.width {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

class AppUICollectionViewLayout: UICollectionViewLayout {
    private enum LayoutItem: String {
        case item = "Item"
        case header = "UICollectionElementKindSectionHeader"
        case footer = "UICollectionElementKindSectionFooter"
    }
    private var cache = [LayoutItem: [IndexPath: UICollectionViewLayoutAttributes]]()
    private func prepareCache() {
        cache.removeAll()
        
        if itemSize == .zero {
            itemSize = CGSize(width: self.collectionView?.bounds.height ?? 0, height: self.collectionView?.bounds.height ?? 0)
        }
        
        cache[.item] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.header] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.footer] = [IndexPath: UICollectionViewLayoutAttributes]()
    }
    
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
    
    private var numberOfItems: Int {
        return collectionView?.numberOfItems(inSection: 0) ?? 0
    }
    
    private var collectionViewSize: CGSize {
        return collectionView?.frame.size ?? .zero
    }
    
    var itemSize: CGSize = .zero
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

class AppUICollectionViewCell: CustomCollectionViewCell {
    @IBOutlet private weak var selectionView: UIView!
    
    @IBOutlet private  weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidthLayout: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewTopLayout: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomLayout: NSLayoutConstraint!
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func initialize() {
        super.initialize()
        
        selectionView.layer.borderColor = tintColor.cgColor
        selectionView.layer.borderWidth = 3
    }
    
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
    
    var imageInsets: UIEdgeInsets = .zero
    
    private func layoutContents() {
        imageViewWidthLayout.constant = image == nil ? 0 : (min(contentView.bounds.width, contentView.bounds.height) - imageInsets.left - imageInsets.right)
        imageViewTopLayout.constant = 2 + imageInsets.top
        imageViewBottomLayout.constant = 2 + imageInsets.bottom
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

class AppUICollectionStackView: AppUICollectionView {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
