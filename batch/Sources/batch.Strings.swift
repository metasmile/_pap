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

struct batchStrings {
    static var appStoreId:String{
        return "1310420792"
    }

    static var name:String{
        return Bundle.main.displayName ?? "Batch Photos"
    }

    static var title: String{
        return "Handle lots of photos at once.".localized
    }

    static var nameTitle:String{
        return "\(name) - \(title)"
    }

    static var tagline: String{
        return "Just select photos you need and then run it.".localized
    }
    
    static var nameTitleTagLine:String{
        return "\(nameTitle): \(tagline)"
    }    

    struct download{
        static var url: String{
            return "https://get.batch.photos"
        }

        static var urlWithoutScheme: String{
            return "get.batch.photos"
        }

        static var urlFirst: String{
            return "%@ Download now for FREE!".localizedFormatted(urlWithoutScheme)
        }

        static var messageFirst: String{
            return "Download now for FREE at %@".localizedFormatted(urlWithoutScheme)
        }
    }

    struct youapp{
        static var url: String{
            return "https://you.batch.photos"
        }

        static var email: String{
            return "you@batch.photos"
        }

        struct l10n {
            static var email: String{
                return "you.l10n@batch.photos"
            }
        }
    }

    struct contact{
        struct feedback {
            static var email: String{
                return "feedback@batch.photos"
            }
        }

        struct support {
            static var email: String{
                return "support@batch.photos"
            }
            static var url: String{
                return "https://batch.photos"
            }
        }

        struct vip{
            static var email: String{
                return "vip@batch.photos"
            }
        }

    }

    struct social {

        struct blog {
            static var url: String{
                return "https://batch.photos/blog"
            }
        }

        struct twitter{
            static var accountName:String{
                return "BatchPhotos"
            }
        }

        struct facebook{
            static var url: String{
                return "https://batch.photos/social"
            }

            static var groupUrl: String{
                return "https://batch.photos/users"
            }

            static var pageId:String{
                return "616758765335887"
            }

            static var groupId:String{
                return "306963843233211"
            }
        }

        struct youtube{
            static var url:String{
                return "https://batch.photos/youtube"
            }

            static var channelId:String{
                return "UCqV5_LkVQMZnqDPTiG12toQ"
            }
        }
    }

    struct info{
        struct engineering {
            static var url: String{
                return "https://batch.photos/engineering"
            }
        }

        struct appsIndex {
            static var url: String{
                return "https://batch.photos/list"
            }
        }

        struct guide {
            static var url: String{
                return "https://batch.photos/guide"
            }
        }

        struct privacy {
            static var email: String{
                return "info@batch.photos"
            }
            static var url: String{
                return "https://batch.photos/privacy"
            }
        }

        struct terms {
            static var email: String{
                return privacy.email
            }
            static var url: String{
                return "https://batch.photos/terms"
            }
            static var urlForAutoRenewalSubscription: String{
                return "https://batch.photos/terms#arp"
            }
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
            return "\(nameTitle)\n\(download.messageFirst)"
        }

        static var messageFirst: String{
            return "\(nameTitle)\n\(tagline) \(download.messageFirst)"
        }

        static var hashTags: [String]{
            return [
                "#BatchPhotos",
                "#GetBatchPhotos"
            ]
        }
    }
}
