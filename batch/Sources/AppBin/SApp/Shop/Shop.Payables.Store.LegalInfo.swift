//
// Created by BLACKGENE on 2018-09-25.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private struct StorePayableLegalInfoStore{
    static var viewController:ActionViewController?
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

        var info = ActionViewItem(title: "Terms", description: type(of: self).product.legalInfo?.notice)
        info.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        info.descriptionStyle = ActionViewItemLabelStyle(textColor: nil, font: UIFont.systemFont(ofSize: UIFont.systemFontSize/1.5), useUpperCase: false)

        var terms = ActionViewItem(title: "Notice", description: "Terms of Use".localized)
        terms.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        terms.descriptionStyle = ActionViewItemLabelStyle(textColor: vc.view.tintColor, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.termsOfUse{
            terms.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        var privacyPolicy = ActionViewItem(title: "Notice", description: "Privacy Policy".localized)
        privacyPolicy.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        privacyPolicy.descriptionStyle = ActionViewItemLabelStyle(textColor: vc.view.tintColor, font: nil, useUpperCase: false)
        if let url = type(of: self).product.legalInfo?.privacyPolicy{
            privacyPolicy.tappedHandler = {
                UIApplication.openSafari(with: url)
            }
        }

        var product = ActionViewItem(title: "Product", description: AppCenter.charge.getCharge(for: type(of: payable))?.rewardDescribable?.title)
        product.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        product.descriptionStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        let unitString = type(of: payable).product.subscriptionPeriod?.localizedUnitString ?? "-"

        var period = ActionViewItem(title: "Renewal", description: "\("1 %@".localizedFormatted(unitString.localizedCapitalized)), \("Anytime free cancellation.".localized.localizedCapitalized)")
        period.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        period.descriptionStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)

        var price = ActionViewItem(title: "Price", description: "\(type(of: payable).storeProduct?.localizedPrice ?? "-")/\(unitString)")
        price.titleStyle = ActionViewItemLabelStyle(textColor: nil, font: nil, useUpperCase: false)
        price.descriptionStyle = ActionViewItemLabelStyle(textColor: nil, font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize), useUpperCase: false)

        vc.actionProgressView.visible = false
        vc.actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        vc.actionButton.titleLabel?.sizeToFit()
        vc.actionButton.setTitle("Purchase".localized.localizedUppercase, for: .normal)
//        let oh = vc.actionButton.height
        vc.actionButton.sizeToFit()
        vc.actionButton.clipsToBounds = true
//        vc.actionButton.layer.cornerRadius = oh/2
        vc.actionButton.backgroundColor = vc.view.tintColor
        vc.actionButton.tintColor = .white
        vc.actionButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: vc.actionButton.height/2, bottom: 0, right: vc.actionButton.height/2)

        vc.setActionViewItems([
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

private class StorePayableLegalInfoActionViewControllerDelegator: ActionViewControllerDelegate, ActionViewControllerDataSource{
    var completionHandler:((Bool) -> ())?

    let payable:StorePayable
    init(payable:StorePayable){
        self.payable=payable
    }

    func didCancel(_ controller: ActionViewController) {
        controller.actionButton.stopIndicating()

        completionHandler?(false)
    }

    func didComplete(_ controller: ActionViewController) {
        controller.actionButton.startIndicating()

        completionHandler?(true)
    }

    func title(in controller: ActionViewController) -> String? {
        return type(of: payable).storeProduct?.localizedTitle.nilEmpty
                ?? AppCenter.charge.getCharge(for: type(of: payable))?.describable.title
    }

    func imageForTitle(in controller: ActionViewController) -> UIImage? {
        return nil
    }

    func titleForPreparing(in controller: ActionViewController) -> String? {
        return nil
    }

    func titleForProcessing(in controller: ActionViewController) -> String? {
        return nil
    }

    func titleForFinish(in controller: ActionViewController) -> String? {
        return nil
    }

    func titleForAction(in controller: ActionViewController) -> String? {
        return nil
    }

    func imageForAction(in controller: ActionViewController) -> UIImage? {
        return nil
    }
}
