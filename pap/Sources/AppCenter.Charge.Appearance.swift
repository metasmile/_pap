//
// Created by BLACKGENE on 8/15/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import PropertyKit

protocol ChargeButtonAppearanceDefaults:PropertyDefaults{
    var showChargeButtonPercentageInNavigationBar:Bool {set get}
    var showChargeButtonLevelColorInNavigationBar:Bool {set get}
}

extension Defaults: ChargeButtonAppearanceDefaults {
    var showChargeButtonPercentageInNavigationBar: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) } get{ return get(or:false) }
    }

    var showChargeButtonLevelColorInNavigationBar: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) } get{ return get(or:false) }
    }
}

extension ChargeableBarButtonItem{
    private static let ButtonObjectCache = NSCache<NSString,ChargeableBarButtonItem>()
    private static var kButtonObjectNormal:NSString { return #function }

    static func make(appearance:ChargeableButtonAppearance) -> ChargeableBarButtonItem{

        if let a = appearance as? ChargeButtonAppearance {
            let k:NSString
            if let charge = a.charge {
                k = String(describing: charge.reward) as NSString
            }else{
                k = kButtonObjectNormal
            }

            if let cachedItem = ButtonObjectCache.object(forKey: k){
                return cachedItem
            }
        }


        let chargeableButton = ChargeableButton(type: .system, appearance: appearance)
        chargeableButton.imageView?.contentMode = .scaleAspectFit
        chargeableButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)

        chargeableButton.fillMode = [.fill]

        //TODO: apply true when some restrictful conditions (e.g. finished trial days) to induce for paying
        chargeableButton.showsColorLevel = false
        chargeableButton.showsAnimation = false
        chargeableButton.showsPercentage = false

        chargeableButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        chargeableButton.titleEdgeInsets.left = 2
        chargeableButton.titleEdgeInsets.right = -2

        return ChargeableBarButtonItem(button:chargeableButton)
    }
}


struct ChargeButtonAppearance: ChargeableButtonAppearance{
    let charge: ChargeableKey?

    var emptyImage: UIImage? {
        guard let charge = charge else {
            return R.image.systemIconFavoriteLine()
        }

        switch charge.reward{
            case .owned:
                return R.image.systemIconFavoriteLineOwned()
            case .rented:
                return R.image.systemIconFavoriteLineCharging()
            case .blockOfUses where charge.type == .instantAdsShowingAllowance:
                return R.image.systemIconFavoriteAd()
            default:
                return R.image.systemIconFavoriteLine()
        }
    }
    var filledImage: UIImage? {
        return R.image.systemIconFavoriteFill()
    }
}

struct ChargeableRestoreImageAppearance: ChargeableButtonAppearance{

    var emptyImage: UIImage? {
        return R.image.systemIconFavoriteLineRestore()
    }
    var filledImage: UIImage? {
        return R.image.systemIconFavoriteFill()
    }
}

