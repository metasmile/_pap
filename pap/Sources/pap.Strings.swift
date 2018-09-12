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

        struct community {
            static var url: String{
                return "https://apps.photo/users"
            }
        }

        struct guide {
            static var url: String{
                return "https://apps.photo/guide"
            }
        }

        struct social {
            static var url: String{
                return "https://apps.photo/social"
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
