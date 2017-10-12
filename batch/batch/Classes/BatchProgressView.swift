//
//  BatchProgressView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 12..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

class BatchProgressView: CustomView {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}
