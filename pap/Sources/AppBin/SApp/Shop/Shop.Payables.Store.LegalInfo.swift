//
// Created by BLACKGENE on 2018-09-25.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private struct StorePayableLegalInfoStore{
    static var viewController:AppUIActionFinalizationViewController?
}

extension StorePayable{

    func dismissLegalInfo(completionHandler:(() -> ())?=nil) {
        if StorePayableLegalInfoStore.viewController?.isBeingDismissed == true{
            completionHandler?()
            StorePayableLegalInfoStore.viewController = nil
        }else{
            StorePayableLegalInfoStore.viewController?.dismiss(animated: true, completion: {
                completionHandler?()
                StorePayableLegalInfoStore.viewController = nil
            })
        }
    }

    func presentLegalInfo(payable:StorePayable, completionHandler:((Bool) -> ())?=nil) {
        guard let vc = R.storyboard.appStoryboard.pricingViewController() else { return }

        var info = ActionFinalizationItem(title: "Terms", description: type(of: self).product.legalInfo?.notice)
        info.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        info.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: UIFont.systemFont(ofSize: UIFont.systemFontSize/1.5), useUpperCase: false)

        var terms = ActionFinalizationItem(title: "Notice", description: "Terms of Use".localized)
        terms.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        terms.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: vc.view.tintColor, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.termsOfUse{
            terms.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        var privacyPolicy = ActionFinalizationItem(title: "Notice", description: "Privacy Policy".localized)
        privacyPolicy.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        privacyPolicy.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: vc.view.tintColor, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.privacyPolicy{
            privacyPolicy.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        var product = ActionFinalizationItem(title: "Product", description: AppCenter.charge.getCharge(for: type(of: payable))?.rewardDescribable?.title)
        product.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        product.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        let unitString = type(of: payable).product.subscriptionPeriod?.localizedUnitString ?? "-"

        var period = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period2 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period2.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period2.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period3 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period3.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period3.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period4 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period4.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period4.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period5 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period5.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period5.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period6 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period6.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period6.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var period7 = ActionFinalizationItem(title: "Renewal Period", description: "1 %@".localizedFormatted(unitString.localizedCapitalized))
        period7.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period7.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var price = ActionFinalizationItem(title: "Price", description: "\(type(of: payable).storeProduct?.localizedPrice ?? "-")/\(unitString)")
        price.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        price.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize), useUpperCase: false)

//        vc.view.backgroundColor = UIColor.white
        vc.actionProgressView.visible = false
        vc.actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        vc.actionButton.titleLabel?.sizeToFit()
        vc.actionButton.setTitle("Purchase".localized.localizedUppercase, for: .normal)
        vc.actionButton.sizeToFit()
        vc.actionButton.clipsToBounds = true
        vc.actionButton.layer.cornerRadius = vc.actionButton.height/2
        vc.actionButton.backgroundColor = vc.view.tintColor
        vc.actionButton.tintColor = .white
        vc.actionButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: vc.actionButton.height/2, bottom: 0, right: vc.actionButton.height/2)

        vc.setActionFinalizationItems([
            info
            , terms
            , privacyPolicy
            , product
            , period
            , period2
            , period3
            , period4
            , period5
            , period6
            , period7
            , price
        ])

        let delegator = StorePayableLegalInfoActionViewControllerDelegator(payable:payable)
        delegator.completionHandler = completionHandler
        vc.delegate = delegator
        vc.dataSource = delegator
        vc.modalPresentationStyle = .overFullScreen

        StorePayableLegalInfoStore.viewController = vc
        UIViewController.present(vc, animated: true)
    }
}


private class StorePayableLegalInfoActionViewControllerDelegator: AppUIActionFinalizationViewControllerDelegate, AppUIActionFinalizationViewControllerDataSource{
    var completionHandler:((Bool) -> ())?

    let payable:StorePayable
    init(payable:StorePayable){
        self.payable=payable
    }

    func close(_ controller: AppUIActionFinalizationViewController) {
        completionHandler?(false)
    }

    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController) {
        completionHandler?(true)
    }

    func title(in controller: AppUIActionFinalizationViewController) -> String? {
        return type(of: payable).storeProduct?.localizedTitle
                ?? AppCenter.charge.getCharge(for: type(of: payable))?.describable.title
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
        return nil
    }

    func imageForAction(in controller: AppUIActionFinalizationViewController) -> UIImage? {
        return nil
    }
}
