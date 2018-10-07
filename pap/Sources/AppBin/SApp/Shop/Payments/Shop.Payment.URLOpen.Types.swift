//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

protocol URLOpenType {
    static var webUrl:URL?{get}
    static var localUrl:URL?{get}
    static var label:String?{get}
}

extension URLOpenType {
    static var localUrl: URL? {
        return nil
    }
    static var label: String? {
        return nil
    }
}

struct URLOpenTypeSocialPage: URLOpenType {
    static var webUrl: URL?{ return papStrings.social.facebook.url.asURL }

    static var localUrl: URL? {
        //Facebook -> Twitter
        let url:URL = "fb://profile/\(papStrings.social.facebook.pageId)".asURL!
        if UIApplication.shared.canOpenURL(url){
            return url
        }
        return "twitter://user?screen_name=\(papStrings.social.twitter.accountName)".asURL
    }
}

struct URLOpenTypeUserCommunity: URLOpenType {
    static var webUrl: URL?{ return papStrings.social.facebook.groupUrl.asURL }

    static var localUrl: URL? {
        return "fb://group?id=\(papStrings.social.facebook.groupId)".asURL
    }
}

struct URLOpenTypeEngineeringNotes: URLOpenType {
    static var webUrl: URL?{ return papStrings.info.engineering.url.asURL }
}

struct URLOpenTypeVideoTutorials: URLOpenType {
    static var webUrl: URL?{ return papStrings.social.youtube.url.asURL }

    static var localUrl: URL? {
        return "youtube://www.youtube.com/channel/\(papStrings.social.youtube.channelId)".asURL 
    }
}

struct URLOpenTypeAppsIndex: URLOpenType {
    static var webUrl: URL?{ return papStrings.info.appsIndex.url.asURL }
}

struct URLOpenTypeReferenceGuide: URLOpenType {
    static var webUrl: URL?{ return papStrings.info.guide.url.asURL }
}

struct URLOpenTypePrivacyPolicy: URLOpenType {
    static var webUrl: URL?{ return papStrings.info.privacy.url.asURL }
}

struct URLOpenTypeTermsOfUse: URLOpenType {
    static var webUrl: URL?{ return papStrings.info.terms.url.asURL }
}


/*
twitter://user?screen_name=lorenb
twitter://user?id=12345
twitter://status?id=12345
twitter://timeline
twitter://mentions
twitter://messages
twitter://list?screen_name=lorenb&slug=abcd
twitter://post?message=hello%20world
twitter://post?message=hello%20world&in_reply_to_status_id=12345
twitter://search?query=%23hashtag

http://twitter.com/hashtag/{HASHTAG}?src=hash
 */


/*
 * http://wiki.akosma.com/IPhone_URL_Schemes#Facebook
 *
 * fb://profile – Open Facebook app to the user’s profile
fb://friends – Open Facebook app to the friends list
fb://notifications – Open Facebook app to the notifications list (NOTE: there appears to be a bug with this URL. The Notifications page opens. However, it’s not possible to navigate to anywhere else in the Facebook app)
fb://feed – Open Facebook app to the News Feed
fb://events – Open Facebook app to the Events page
fb://requests – Open Facebook app to the Requests list
fb://notes – Open Facebook app to the Notes page
fb://albums – Open Facebook app to Photo Albums list


 http://stackoverflow.com/questions/5707722/what-are-all-the-custom-url-schemes-supported-by-the-facebook-iphone-app

fb://album?id=%@
fb://background_location
fb://browse?semantic=%@&result_type=%d&source_type=%d&title=%@
fb://codegenerator
fb://composer?%@
fb://composer?pagename=%@&pageid=%@
fb://composer?target=%@
fb://composer?view=location
fb://contactimporter/?ci_flow=%d
fb://discovery
fb://entitycards/?ids=%@&source=%@
fb://event?id=%@
fb://event?id=%@&post_id=%@
fb://eventguestlist?event_id=%@
fb://events/list
fb://eventslist?owner_fbid=%@
fb://f(.+)(\?|&)v=map(\&.*)?
fb://f(.+)incorrect_map_pin(\&.*)?
fb://friendsnearby
fb://friendsnearby/?source=%@
fb://friendsnearby/?source=divebar
fb://friendsnearby/ping?fbid=%@&source=%@
fb://friendsnearby/profile?fbid=%@&source=%@
fb://gift?
fb://group?id=%@
fb://group?id=%@&object_id=%@&view=permalink
fb://hashtag/
fb://hashtag/%@
fb://location_settings
fb://messageComposer?
fb://messaging/new
fb://messaging/new?id=%@&name=%@&isPage=%d
fb://messaging?
fb://messaging?id=%@
fb://messaging?id=%@&%@
fb://messaging?tid=%@
fb://messaginglist
fb://page?id=%@
fb://page?id=%@&source=%@&source_id=%@
fb://page_about?id=%@
fb://page_friend_likes_and_visits?id=%@
fb://page_reviews?id=%@
fb://photo?%@
fb://photo?id=%@
fb://pnp?type=instructions
fb://products?%@
fb://profile
fb://profile/%@
fb://profile?id=%@
fb://profile?id=%@&%@=%@
fb://story?%@
fb://story?graphqlid=%@
fb://story?id=%@
fb://timelineappsection?id=%@
fb://topic/%@
fb://uploadcoverphoto
fb://zrnext
 */

/*
 * https://instagram.com/developer/iphone-hooks/?hl=en
 *
app	The Instagram app
camera	The camera (or photo library on non-camera devices)
media?id=MEDIA_ID	Media with this ID
user?username=USERNAME	User with this username
location?id=LOCATION_ID	Location feed for this location ID
tag?name=TAG	Tag feed for this tag

 https://www.instagram.com/explore/tags/eliecam/
 */

