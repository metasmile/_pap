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

struct papStrings {
    static var name:String{
        return Bundle.main.displayName ?? "Photo Apps"
    }

    static var title: String{
        //TODO: decide
        //TODO: Rethink subtitle such as "Camera and Photos Platform"-sided. Not the meaning of action
        return "Do Anything At Once"
    }

    static var nameTitle:String{
        return "\(name) - \(title)"
    }

    static var tagline: String{
        //TODO: decide
        return "A photos app, but contains a lot of sub-apps in its own.".localized
    }

    struct download{
        static var url: String{
            return "https://get.apps.photo"
        }

        static var urlFirst: String{
            return "%@ Download now for FREE!".localizedFormatted(url)
        }

        static var messageFirst: String{
            return "Download now for FREE at %@".localizedFormatted(url)
        }
    }

    struct feedback {
        static var email: String{
            return "feedback@apps.photo"
        }
    }

    struct share{

        static var urlFirstShort: String{
            return "\(download.urlFirst) \(nameTitle)"
        }

        static var urlFirst: String{
            return "\(download.urlFirst) \(nameTitle): \(tagline)"
        }

        static var messageFirstShort: String{
            return "\(nameTitle): \(download.messageFirst)"
        }

        static var messageFirst: String{
            return "\(nameTitle): \(tagline) \(download.messageFirst)"
        }
    }
}
