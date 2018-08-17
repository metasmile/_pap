//
//  PricingViewController.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 24..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

protocol PricingViewControllerDataSource {
    func titleForAction(in controller: PricingViewController) -> String?
    func imageForAction(in controller: PricingViewController) -> UIImage?
}

protocol PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController)
    func pricingViewControllerDidRequestTransaction(_ controller: PricingViewController)
}

internal class PricingContentView: UIView {
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

struct PricingViewItem {
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

internal class PricingTableViewCell: UITableViewCell {
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
        titleImageView.heightAnchor.constraint(greaterThanOrEqualTo: titleImageView.widthAnchor, multiplier: 1).isActive = true
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


class PricingViewController: UIViewController {
    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var cancelButton: UIButton!
    
    @IBOutlet weak var pricingContentView: PricingContentView!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var actionTitleLabel: UILabel!
    
    private var pricingViewItems: [PricingViewItem]?
    var dataSource: PricingViewControllerDataSource?
    var delegate: PricingViewControllerDelegate?
    
    var contentView: UIView? {
        didSet {
            pricingContentView.contentView = contentView
        }
    }
    
    private lazy var pricingTableView: SelfSizedTableView = {
        let tableView = SelfSizedTableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(PricingTableViewCell.self, forCellReuseIdentifier: PricingTableViewCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapToCloseGesture = UITapGestureRecognizer(target: self, action: #selector(self.close))
        backgroundView.addGestureRecognizer(tapToCloseGesture)
        
        if let _ = pricingViewItems {
            contentView = pricingTableView
        }
        
        actionButton.setImage(dataSource?.imageForAction(in: self), for: .normal)
        actionTitleLabel.text = dataSource?.titleForAction(in: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction private func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
        delegate?.pricingViewControllerDidCancel(self)
    }
    
    @IBAction func actionButtonDidTap(_ sender: Any) {
        delegate?.pricingViewControllerDidRequestTransaction(self)
    }
}

extension PricingViewController {
    func setPricingViewItems(_ items: [PricingViewItem]) {
        pricingViewItems = items
    }
}

extension PricingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pricingViewItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PricingTableViewCell.reuseIdentifier, for: indexPath) as! PricingTableViewCell
        if let item = pricingViewItems?[indexPath.row] {
            updateCell(cell, for: item, at: indexPath)
        }
        return cell
    }
    
    private func updateCell(_ cell: PricingTableViewCell, for item: PricingViewItem, at indexPath: IndexPath) {
        cell.titleLabel.text = item.title?.localized.localizedUppercase
        cell.descriptionLabel.text = item.description?.localized.localizedUppercase
        cell.titleImageView.image = item.image
    }
}

extension PricingViewController: UITableViewDelegate {}
