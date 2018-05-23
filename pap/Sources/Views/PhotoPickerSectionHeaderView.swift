//
//  PhotoPickerSectionHeaderView.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation

class PhotoPickerSectionHeaderView: UICollectionReusableView {
    lazy var appIconView: RoundedView = {
        let view = RoundedView()
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
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
        addSubview(appIconView)
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        appIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        appIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // 120x90
        let iconRatio: CGFloat = 120 / 90
        appIconView.widthAnchor.constraint(equalToConstant: bounds.height / 2).isActive = true
        appIconView.heightAnchor.constraint(equalToConstant: bounds.height / 2 / iconRatio).isActive = true
        
        appIconView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: appIconView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: appIconView.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: appIconView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: appIconView.trailingAnchor).isActive = true
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 8).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        appIconView.cornerRadius = appIconView.bounds.height * 0.5
    }
}
