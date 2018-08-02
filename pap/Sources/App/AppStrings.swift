//
// Created by BLACKGENE on 11.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// scheme: Strings.{verb/how}.{sub-verb/to act}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: Strings.{verb/how}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: Strings.{noun-what(category/detail/situation)}.?{adverb}

//INFO: Common message only for pap.
//WARNING: DO NOT USE on CodeKit, Sources/App or independent codes.

struct AppStrings {

    struct cannot{
        struct detect {
            static var information:String{
                return "Did not detect anything.".localized
            }
        }

        static var save:String{
            return "It could not be stored.".localized
        }
    }

    struct be {
        struct wrong {
            static var something:String{
                return "Sorry, something went wrong.".localized
            }
        }
    }
}