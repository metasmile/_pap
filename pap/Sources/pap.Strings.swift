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
    static var appStoreId:String{
        return "1309539102"
    }

    static var name:String{
        return Bundle.main.displayName ?? "Photo Apps"
    }

    static var title: String{
        return "Do Everything With Photos.".localized
    }

    static var nameTitle:String{
        return "\(name) - \(title)"
    }

    static var tagline: String{
        return "An App, But Contains Many Photo Apps.".localized
    }
    
    static var nameTitleTagLine:String{
        return "\(nameTitle): \(tagline)"
    }    

    struct download{
        static var url: String{
            return "https://get.apps.photo"
        }

        static var urlWithoutScheme: String{
            return "get.apps.photo"
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
            return "https://you.apps.photo"
        }

        static var email: String{
            return "you@apps.photo"
        }

        struct l10n {
            static var email: String{
                return "you.l10n@apps.photo"
            }
        }
    }

    struct contact{
        struct feedback {
            static var email: String{
                return "feedback@apps.photo"
            }
        }

        struct support {
            static var email: String{
                return "support@apps.photo"
            }
            static var url: String{
                return "https://apps.photo"
            }
        }

        struct vip{
            static var email: String{
                return "vip@apps.photo"
            }
        }

    }

    struct social {

        struct twitter{
            static var accountName:String{
                return "AppsForPhotos"
            }
        }

        struct facebook{
            static var url: String{
                return "https://apps.photo/social"
            }

            static var groupUrl: String{
                return "https://apps.photo/users"
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
                return "https://apps.photo/youtube"
            }

            static var channelId:String{
                return "UCqV5_LkVQMZnqDPTiG12toQ"
            }
        }
    }

    struct info{
        struct engineering {
            static var url: String{
                return "https://apps.photo/engineering"
            }
        }

        struct appsIndex {
            static var url: String{
                return "https://apps.photo/list"
            }
        }

        struct guide {
            static var url: String{
                return "https://apps.photo/guide"
            }
        }

        struct privacy {
            static var email: String{
                return "info@apps.photo"
            }
            static var url: String{
                return "https://apps.photo/privacy"
            }
        }

        struct terms {
            static var email: String{
                return privacy.email
            }
            static var url: String{
                return "https://apps.photo/terms"
            }
            static var urlForAutoRenewalSubscription: String{
                return "https://apps.photo/terms#arp"
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
                "#PhotoApps",
                "#GetPhotoApps"
            ]
        }
    }
}
