//
//  App.PreviewView.Actionable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public protocol AppPreviewActionable: App {
    var titleForAction: String? {get}
    func didAction(with appAsset: AppAsset)
}
