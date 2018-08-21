//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


protocol URLVisitingType {
    static var url:URL?{get}
}

struct URLVisitingTypeTwitter: URLVisitingType {
    static var url: URL?{ return "https://twitter.com/AppsForPhotos".asURL }
}

struct URLVisitingTypeFacebook: URLVisitingType {
    static var url: URL?{ return "https://www.facebook.com/apps.photo".asURL }
}
