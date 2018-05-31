//
// Created by BLACKGENE on 31.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import CoreSpotlight
import UIKit

private let LocalizableKeywordPrefix = "cs_keyword_"
private let LocalizableKeywordLastIndexNumber = 13;

private extension Array where Element==CSSearchable{
    var searchableItems:[CSSearchableItem]{
        return self.map { $0.createItem() }
    }
}

private struct CSSearchable {
    static let host = "com.stells.corespotlight"
    let suffix:String
    var attributeSet:CSSearchableItemAttributeSet? = nil
    var domain:String? = "default"

    var identifier:String{
        return type(of: self).host+suffix
    }

    func createItem() -> CSSearchableItem {
       let item = CSSearchableItem()
        item.uniqueIdentifier = self.identifier
        item.domainIdentifier = self.domain
        if let attr = self.attributeSet{
            item.attributeSet = attr
        }
        return item
    }

    init(suffix:String, domain:String?=nil, attributeSet:CSSearchableItemAttributeSet?=nil){
        self.suffix = suffix
        self.domain = domain
        self.attributeSet = attributeSet
    }
}

extension CSSearchable{
    init(app:App.Type){

        let csItemAttr = CSSearchableItemAttributeSet(itemContentType: UTI.image.rawValue)
        csItemAttr.title = app.info.displayName
        csItemAttr.contentDescription = app.info.description
        csItemAttr.keywords = app.info.keywords
        if let image = app.info.iconBundleName?.asUIImage{
            csItemAttr.thumbnailData = UIImagePNGRepresentation(image)
        }
        self.init(suffix: app.info.identifier, domain: String(describing: App.self), attributeSet: csItemAttr)
    }
}

extension AppDelegate{

    //TODO: if user selects sub app name -> Photo Apps Launch -> current App Selected

    //INFO: background queue recommended.
    func indexDefaultSearchableItems(){
        var items = [CSSearchable]()

        //main item
        let csItemAttr = CSSearchableItemAttributeSet(itemContentType: UTI.image.rawValue)
        csItemAttr.title = Bundle.main.displayName
        csItemAttr.contentDescription = "Do Anything, At Once.".localized
        csItemAttr.keywords = Array(0 ... LocalizableKeywordLastIndexNumber).map { e -> String in
            return (LocalizableKeywordPrefix+String(e)).localized
        }
        items.append(CSSearchable(suffix: ".main"))

        //apps
        let appItems = AppCenter.default.apps(by: AppQuery.default).map { appType -> CSSearchable in
            return CSSearchable(app:appType)
        }
        items.append(contentsOf: appItems)

        CSSearchableIndex.default().indexSearchableItems(items.searchableItems) { error in
            assert(error==nil, "indexSearchableItems has an error.")
        }
    }
}