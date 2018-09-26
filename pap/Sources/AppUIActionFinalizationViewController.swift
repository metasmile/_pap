//
//  AppUIActionFinalizationViewController.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 24..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

extension AppUIActionFinalizationViewController {
    enum ProcessingRepresentationType {
        case loading
        case progress
    }
}

protocol AppUIActionFinalizationViewControllerDataSource {
    func title(in controller: AppUIActionFinalizationViewController) -> String?
    func image(in controller: AppUIActionFinalizationViewController) -> UIImage?
    
    func titleForAction(in controller: AppUIActionFinalizationViewController) -> String?
    func imageForAction(in controller: AppUIActionFinalizationViewController) -> UIImage?
    
    func titleForPreparing(in controller: AppUIActionFinalizationViewController) -> String?
    func titleForProcessing(in controller: AppUIActionFinalizationViewController) -> String?
    func titleForFinish(in controller: AppUIActionFinalizationViewController) -> String?
}

extension AppUIActionFinalizationViewControllerDataSource {
    func title(in controller: AppUIActionFinalizationViewController) -> String? {
        return Bundle.main.displayName
    }
    
    func image(in controller: AppUIActionFinalizationViewController) -> UIImage? { return nil }
    
    func titleForPreparing(in controller: AppUIActionFinalizationViewController) -> String? { return "Preparing".localized }
    func titleForProcessing(in controller: AppUIActionFinalizationViewController) -> String? { return "Processing".localized }
    func titleForFinish(in controller: AppUIActionFinalizationViewController) -> String? { return "Done".localized }
}

protocol AppUIActionFinalizationViewControllerDelegate {
    func close(_ controller: AppUIActionFinalizationViewController)
    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController)
}

internal class ActionFinalizationContentView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    var contentView: UIView? {
        didSet {
            if let view = contentView {
                addSubview(view)
                view.fitConstraints(to: self)
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        contentView?.layoutIfNeeded()
        contentView?.invalidateIntrinsicContentSize()
        return CGSize(width: UIViewNoIntrinsicMetric, height: contentView?.intrinsicContentSize.height ?? UIViewNoIntrinsicMetric)
    }
}

struct ActionFinalizationItemLabelStyle{
    let textColor:UIColor?
    let font:UIFont?
    let useUpperCase:Bool
}

struct ActionFinalizationItem {
    var title: String?
    var titleStyle:ActionFinalizationItemLabelStyle?

    var description: String?
    var descriptionStyle: ActionFinalizationItemLabelStyle?

    var image: UIImage?

    var tappedHandler:(() -> ())?=nil

    init(title: String? = nil, description: String? = nil) {

        self.title = title
        self.description = description
    }
    
    init(image: UIImage? = nil, description: String? = nil) {
        self.image = image
        self.description = description
    }
}

internal class ActionFinalizationTableViewCell: UITableViewCell {
    class var reuseIdentifier: String {
        return String(describing: ActionFinalizationTableViewCell.self)
    }

    var tappedHandler:(() -> ())?=nil
    var titleDescriptionSeparationWidth:CGFloat = 10
    var titleDescriptionAreaInset:UIEdgeInsets = UIEdgeInsets.init(top: 11, left: 10, bottom: 11, right: 10)
    var titleLabelHorizontalMultiplier:CGFloat = 0.25

    fileprivate lazy var titleTextView: UITextView = {
        let label = UITextView(frame: .zero)
        label.textColor = defaultTitleLabelStyle.textColor
        label.font = defaultTitleLabelStyle.font
        label.textAlignment = .right
        label.textContainer.maximumNumberOfLines = 0
        label.textContainer.lineBreakMode = .byWordWrapping
        label.isScrollEnabled = false
        label.backgroundColor = UIColor.clear
        label.adjustsFontForContentSizeCategory = true
        label.isUserInteractionEnabled = false
        label.textContainerInset = UIEdgeInsets.zero
        return label
    }()

    fileprivate let defaultTitleLabelStyle = (
            textColor: UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1)
            , font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
    )
    
    fileprivate lazy var descriptionTextView: UITextView = {
        let label = UITextView(frame: .zero)
        label.textColor = defaultDescriptionLabelStyle.textColor
        label.font = defaultDescriptionLabelStyle.font
        label.textAlignment = .left
        label.textContainer.maximumNumberOfLines = 0
        label.textContainer.lineBreakMode = .byWordWrapping
        label.isScrollEnabled = false
        label.backgroundColor = UIColor.clear
        label.adjustsFontForContentSizeCategory = true
        label.isUserInteractionEnabled = false
        label.textContainerInset = UIEdgeInsets.zero

        return label
    }()

    fileprivate let defaultDescriptionLabelStyle = (
            textColor: UIColor.black
            ,font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
    )
    
    fileprivate lazy var titleImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = nil
        
        let container = UIView(frame: .zero)
        contentView.addSubview(container)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: titleDescriptionAreaInset.top).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleDescriptionAreaInset.bottom).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: titleDescriptionAreaInset.left).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -titleDescriptionAreaInset.right).isActive = true
        
        container.addSubview(titleTextView)
        titleTextView.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        titleTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        titleTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        titleTextView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: titleLabelHorizontalMultiplier).isActive = true
        
        container.addSubview(titleImageView)
        titleImageView.translatesAutoresizingMaskIntoConstraints = false
        titleImageView.widthAnchor.constraint(equalTo: container.heightAnchor).isActive = true
        titleImageView.heightAnchor.constraint(greaterThanOrEqualTo: titleImageView.widthAnchor, multiplier: 1).isActive = true

        titleImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: titleDescriptionAreaInset.top).isActive = true
        titleImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: titleDescriptionAreaInset.bottom).isActive = true
        titleImageView.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor).isActive = true
        
        container.addSubview(descriptionTextView)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        descriptionTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        descriptionTextView.leadingAnchor.constraint(equalTo: titleTextView.trailingAnchor, constant: titleDescriptionSeparationWidth).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleTextView.text = nil
        descriptionTextView.text = nil
        titleImageView.image = nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if tappedHandler != nil{
            setHighlighted(true, animated: false)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if tappedHandler != nil{
            setHighlighted(false, animated: true)
        }

        tappedHandler?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        if tappedHandler != nil{
            setHighlighted(false, animated: false)
        }
    }
}

internal class SelfSizedTableView: UITableView {
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {

        var inset:CGFloat = 0
        if let root = UIViewController.root{
            inset += root.safeAreaInsets.bottom + root.safeAreaInsets.top
            inset += root.additionalSafeAreaInsets.bottom + root.additionalSafeAreaInsets.top
        }
        let height = min(contentSize.height, maxIntrinsicContentSizeHeight ?? UIScreen.main.bounds.size.height - inset)
        return CGSize(width: contentSize.width, height: height)
    }

    var maxIntrinsicContentSizeHeight:CGFloat?
}

class AppUICircleProgressView: DesignableView {
    lazy var trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.lightGray.cgColor
        layer.lineWidth = 6
        layer.fillColor = nil
        return layer
    }()
    
    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = tintColor.cgColor
        layer.lineWidth = 6
        layer.fillColor = nil
        return layer
    }()
    
    override func initialize() {
        super.initialize()
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        
        progress = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: bounds.width / 2, startAngle:  -CGFloat.pi / 2, endAngle: CGFloat.pi * 2 - CGFloat.pi / 2, clockwise: true)
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    var progress: CGFloat = 0.0 {
        willSet {
            progressLayer.strokeEnd = newValue
        }
    }
}


class AppUIActionFinalizationViewController: UIViewController {
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var cancelButton: UIButton!
    
    @IBOutlet weak var contentView: ActionFinalizationContentView!

    @IBOutlet weak var actionView: UIView!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var actionTitleLabel: UILabel!
    
    @IBOutlet weak var actionProgressView: AppUICircleProgressView!
    
    private var items: [ActionFinalizationItem]?
    var dataSource: AppUIActionFinalizationViewControllerDataSource?
    var delegate: AppUIActionFinalizationViewControllerDelegate?
    
    private lazy var tableView: SelfSizedTableView = {
        let tableView = SelfSizedTableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(ActionFinalizationTableViewCell.self, forCellReuseIdentifier: ActionFinalizationTableViewCell.reuseIdentifier)
        tableView.backgroundColor = .clear

        let safeAreaFrame = UIViewController.root?.view.safeAreaLayoutGuide.layoutFrame ?? CGRect.zero
        tableView.maxIntrinsicContentSizeHeight = safeAreaFrame.height - safeAreaFrame.origin.y*2.1 - (actionView.constraints.first { $0.firstAttribute == .height && $0.relation == .equal }?.constant ?? 0)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        let tapToCloseGesture = UITapGestureRecognizer(target: self, action: #selector(self.closeButtonDidTap))
        backgroundView.addGestureRecognizer(tapToCloseGesture)

        contentView.contentView = tableView

        titleLabel.text = dataSource?.title(in: self)
        titleImageView.image = dataSource?.image(in: self)
        titleImageView.sizeToFit()

        actionButton.setImage(dataSource?.imageForAction(in: self), for: .normal)
        actionTitleLabel.text = dataSource?.titleForAction(in: self)

        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func closeButtonDidTap(_ sender: Any) {
        close()
    }
    
    @IBAction func actionButtonDidTap(_ sender: Any) {
        delegate?.actionFinalizationViewControllerDidAction(self)
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
        delegate?.close(self)
    }
}

extension AppUIActionFinalizationViewController {
    func setActionFinalizationItems(_ items: [ActionFinalizationItem]) {
        self.items = items
    }
}

extension AppUIActionFinalizationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActionFinalizationTableViewCell.reuseIdentifier, for: indexPath) as! ActionFinalizationTableViewCell
        if let item = items?[indexPath.row] {
            updateCell(cell, forItem: item)
        }
        return cell
    }
    
    private func updateCell(_ cell: ActionFinalizationTableViewCell, forItem item: ActionFinalizationItem) {
        cell.titleTextView.text = item.titleStyle?.useUpperCase == true ? item.title?.localizedUppercase : item.title
        cell.titleTextView.textColor = item.titleStyle?.textColor ?? cell.defaultTitleLabelStyle.textColor
        cell.titleTextView.font = item.titleStyle?.font ?? cell.defaultTitleLabelStyle.font

        cell.descriptionTextView.text = item.descriptionStyle?.useUpperCase == true ? item.description?.localizedUppercase : item.description
        cell.descriptionTextView.textColor = item.descriptionStyle?.textColor ?? cell.defaultDescriptionLabelStyle.textColor
        cell.descriptionTextView.font = item.descriptionStyle?.font ?? cell.defaultDescriptionLabelStyle.font

        cell.titleImageView.image = item.image
        cell.tappedHandler = item.tappedHandler
    }
    
    private func updateCellForItem(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ActionFinalizationTableViewCell else { return }
        if let item = items?[indexPath.row] {
            updateCell(cell, forItem: item)
        }
    }
}

extension AppUIActionFinalizationViewController: UITableViewDelegate {}

extension AppUIActionFinalizationViewController {
    func actionProgressDidBegin(actionTitle: String?) {
        actionTitleLabel.text = actionTitle
        
        actionProgressView.isHidden = false
        actionProgressView.progress = 0
    }
    
    func actionProgressDidUpdate(actionTitle: String?, progress: Float) {
        actionTitleLabel.text = actionTitle
        
        actionProgressView.isHidden = false
        actionProgressView.progress = CGFloat(progress)
    }
    
    func actionProgressDidFinish(actionTitle: String?) {
        actionTitleLabel.text = actionTitle
    }
}
