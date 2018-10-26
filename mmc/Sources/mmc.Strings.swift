//
// Created by BLACKGENE on 8/2/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// scheme: Strings.{verb/how}.{sub-verb/to act}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: Strings.{verb/how}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: Strings.{noun-what(category/detail/situation)}.?{adverb}

//INFO: Common message only for pap.
//WARNING: DO NOT USE on CodeKit, Sources/App or independent codes.

struct mmcStrings {
    static var appStoreId:String{
        return "1402594534"
    }

    static var name:String{
        return Bundle.main.displayName ?? "Memo Cam"
    }

    static var title: String{
        return "Get Every Info Around You.".localized
    }

    static var nameTitle:String{
        return "\(name) - \(title)"
    }

    static var tagline: String{
        return "Get Text And Then Do Something.".localized
    }
    
    static var nameTitleTagLine:String{
        return "\(nameTitle): \(tagline)"
    }    

    struct download{
        static var url: String{
            return "https://get.memo.cam"
        }

        static var urlWithoutScheme: String{
            return "get.memo.cam"
        }

        static var urlFirst: String{
            return "%@ Download now for FREE!".localizedFormatted(urlWithoutScheme)
        }

        static var messageFirst: String{
            return "Download now for FREE at %@".localizedFormatted(urlWithoutScheme)
        }
    }

}
