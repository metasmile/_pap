//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

class PhotoPickerFooterView: UICollectionReusableView {
    lazy var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 16)
        view.textAlignment = .center
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
        addSubview(label)
        
        label.fitConstraints(to: self)
    }

    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        text = nil
    }
}
