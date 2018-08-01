//
// Created by BLACKGENE on 11.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// scheme: AppMsg.{verb/how}.{sub-verb/to act}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: AppMsg.{verb/how}.{noun-what(category/detail/situation)}.?{adverb}
// scheme: AppMsg.{noun-what(category/detail/situation)}.?{adverb}

//INFO: Common message only.
struct AppMsg {
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