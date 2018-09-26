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

        var period = ActionFinalizationItem(title: "Renewal", description: "\("1 %@".localizedFormatted(unitString.localizedCapitalized)), \("Anytime free cancellation.".localized.localizedCapitalized)")
        period.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var price = ActionFinalizationItem(title: "Price", description: "\(type(of: payable).storeProduct?.localizedPrice ?? "-")/\(unitString)")
        price.titleStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        price.descriptionStyle = ActionFinalizationItemLabelStyle(textColor: nil, font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize), useUpperCase: false)

        vc.actionProgressView.visible = false
        vc.actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        vc.actionButton.titleLabel?.sizeToFit()
        vc.actionButton.setTitle("Purchase".localized.localizedUppercase, for: .normal)
        let oh = vc.actionButton.height
        vc.actionButton.sizeToFit()
        vc.actionButton.clipsToBounds = true
        vc.actionButton.layer.cornerRadius = oh/2
        vc.actionButton.backgroundColor = vc.view.tintColor
        vc.actionButton.tintColor = .white
        vc.actionButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: vc.actionButton.height/2, bottom: 0, right: vc.actionButton.height/2)

        vc.setActionFinalizationItems([
            info
            , terms
            , privacyPolicy
            , product
            , period
            , price
        ])

        let delegator = StorePayableLegalInfoActionViewControllerDelegator(payable:payable)
        delegator.completionHandler = completionHandler
        vc.delegate = delegator
        vc.dataSource = delegator

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
        controller.actionButton.stopIndicating()

        completionHandler?(false)
    }

    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController) {
        controller.actionButton.startIndicating()

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
