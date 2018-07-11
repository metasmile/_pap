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
                return "Sorry. No information about you have selected could not be detected.".localized
            }
        }

        static var save:String{
            return "Sorry, it could not be saved.".localized
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