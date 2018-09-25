//
// Created by BLACKGENE on 2018-09-25.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension StorePayable{
    func displayLegalInfo(completionHandler:((Bool) -> ())?=nil) {
        guard let vc = R.storyboard.appStoryboard.pricingViewController() else { return }

        var info = ActionFinalizationItem(title: "Information", description: type(of: self).product.legalInfo?.notice)
        info.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        info.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var t = ActionFinalizationItem(title: "Learn More".localized, description: "Terms of Use".localized)
        t.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        t.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.termsOfUse{
            t.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        var p = ActionFinalizationItem(title: "Learn More".localized, description: "Privacy Policy".localized)
        p.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        p.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.privacyPolicy{
            p.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        let delegator = StorePayableLegalInfoActionViewControllerDelegator()
        delegator.completionHandler = completionHandler
        vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        vc.setActionFinalizationItems([
            info
            , t
            , p
        ])
        vc.delegate = delegator
        vc.dataSource = delegator

        UIViewController.present(vc, animated: true)
    }
}


private class StorePayableLegalInfoActionViewControllerDelegator: AppUIActionFinalizationViewControllerDataSource,AppUIActionFinalizationViewControllerDelegate {
    var completionHandler:((Bool) -> ())?

    func title(in controller: AppUIActionFinalizationViewController) -> String? {
        return "Purchase"
    }

    func image(in controller: AppUIActionFinalizationViewController) -> UIImage? {
        return nil
    }

    func titleForPreparing(in controller: AppUIActionFinalizationViewController) -> String? {
        return nil
    }

    func titleForProcessing(in controller: AppUIActionFinalizationViewController) -> String? {
        return nil
    }

    func titleForFinish(in controller: AppUIActionFinalizationViewController) -> String? {
        return nil
    }

    func titleForAction(in controller: AppUIActionFinalizationViewController) -> String? {
        return "Purchase"
    }

    func imageForAction(in controller: AppUIActionFinalizationViewController) -> UIImage? {
        return nil
    }

    func close(_ controller: AppUIActionFinalizationViewController) {
        completionHandler?(false)
    }

    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController) {
        completionHandler?(true)
    }
}
