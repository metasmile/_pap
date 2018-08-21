//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


protocol URLVisitingType {
    static var url:URL?{get}
    static var label:String?{get}
}

extension URLVisitingType{
    static var label: String? {
        return nil
    }
}

struct URLVisitingTypeTwitter: URLVisitingType {
    static var url: URL?{ return "https://twitter.com/AppsForPhotos".asURL }
}

struct URLVisitingTypeFacebook: URLVisitingType {
    static var url: URL?{ return "https://www.facebook.com/apps.photo".asURL }
}

//TODO: YOU. app compaign - must check submit state - Typeform? PH Survey? hm
struct URLVisitingTypeProductHuntSurvey: URLVisitingType {
    static var url: URL?{ return "https://apps.photo/youapp".asURL }
    static var label: String? {
        return "Join".localized
    }
}

