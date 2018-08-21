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
}

extension AppUIActionFinalizationViewControllerDataSource {
    func title(in controller: AppUIActionFinalizationViewController) -> String? {
        return Bundle.main.displayName
    }
    
    func image(in controller: AppUIActionFinalizationViewController) -> UIImage? { return nil }
}

protocol AppUIActionFinalizationViewControllerDelegate {
    func actionFinalizationViewControllerDidClose(_ controller: AppUIActionFinalizationViewController)
    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController)
    
    func actionFinalizationViewControllerDidCancel(_ controller: AppUIActionFinalizationViewController)
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

struct ActionFinalizationItem {
    var title: String?
    var description: String?
    var image: UIImage?
    
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
        return "PricingTableViewCell"
    }
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    
    fileprivate lazy var descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
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
        container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6).isActive = true
        
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.25).isActive = true
        
        container.addSubview(titleImageView)
        titleImageView.translatesAutoresizingMaskIntoConstraints = false
        titleImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        titleImageView.heightAnchor.constraint(lessThanOrEqualTo: titleImageView.widthAnchor, multiplier: 1).isActive = true
        titleImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        titleImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        titleImageView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        
        container.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        descriptionLabel.text = nil
        titleImageView.image = nil
    }
}

internal class SelfSizedTableView: UITableView {
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        let height = min(contentSize.height, UIScreen.main.bounds.size.height)
        return CGSize(width: contentSize.width, height: height)
    }
}

class AppUICircleProgressView: DesignableView {
    lazy var trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.lightGray.cgColor
        layer.lineWidth = 4
        layer.fillColor = nil
        return layer
    }()
    
    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = tintColor.cgColor
        layer.lineWidth = 4
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
    
    var progress: Float = 0.0 {
        willSet {
            progressLayer.strokeEnd = CGFloat(newValue)
        }
    }
}

// inspired by PKPaymentAuthorizationViewController

class AppUIActionFinalizationViewController: UIViewController {
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var cancelButton: UIButton!
    
    @IBOutlet weak var contentView: ActionFinalizationContentView!
    
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
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapToCloseGesture = UITapGestureRecognizer(target: self, action: #selector(self.closeButtonDidTap))
        backgroundView.addGestureRecognizer(tapToCloseGesture)
        
        contentView.contentView = tableView
        
        titleLabel.text = dataSource?.title(in: self)
        titleImageView.image = dataSource?.image(in: self)
        titleImageView.sizeToFit()
        
        actionButton.setImage(dataSource?.imageForAction(in: self), for: .normal)
        actionTitleLabel.text = dataSource?.titleForAction(in: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction private func closeButtonDidTap(_ sender: Any) {
        delegate?.actionFinalizationViewControllerDidCancel(self)
    }
    
    @IBAction func actionButtonDidTap(_ sender: Any) {
        delegate?.actionFinalizationViewControllerDidAction(self)
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
        delegate?.actionFinalizationViewControllerDidClose(self)
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
        cell.titleLabel.text = item.title?.localized.localizedUppercase
        cell.descriptionLabel.text = item.description?.localized.localizedUppercase
        cell.titleImageView.image = item.image
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
        actionProgressView.progress = progress
    }
    
    func actionProgressDidFinish(actionTitle: String?) {
        actionTitleLabel.text = actionTitle
    }
}
