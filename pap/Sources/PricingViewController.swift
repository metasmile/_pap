//
//  PricingViewController.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 24..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

enum PricingTeer: String {
    case freeTrial = "Free Trial"
    case subscription = "Subscription"
}

protocol PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController)
}

class PricingViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate: PricingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapToCloseGesture = UITapGestureRecognizer(target: self, action: #selector(self.close))
        backgroundView.addGestureRecognizer(tapToCloseGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.transition(with: backgroundView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.backgroundView.isHidden = false
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.transition(with: backgroundView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.backgroundView.isHidden = true
        }, completion: nil)
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
        delegate?.pricingViewControllerDidCancel(self)
    }
}
