//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

typealias MailContactTypeAttributes = (addresses:[String], subject:String, messageAfterSent:String?)

protocol MailContactType {
    static var isEnable: Bool {get}
    static var attributes: MailContactTypeAttributes {get}
    static func prepareMessage(_ asyncSignal:AsyncWaitSignalable) -> (content:String, isHTML:Bool)?
}

extension MailContactType{
    static var isEnable: Bool {
        return true
    }

    static func prepareMessage(_ asyncSignal: AsyncWaitSignalable) -> (content: String, isHTML: Bool)? {
        return nil
    }
}

struct MailContactFeedbackType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        return (
                addresses: [papStrings.contact.feedback.email]
                , subject: "👋 " + "My Feedback on %@".localizedFormatted(papStrings.name)
                , messageAfterSent: "Thank you very much for your feedback! Soon we will contact you.".localized
        )
    }
}

struct MailContactSupportType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        return (
                addresses: [papStrings.contact.support.email]
                , subject: "[\(UUID().uuidString.split(separator: "-")[0])] I need some help while using this app."
                , messageAfterSent: "Thank you for your message. Soon we will contact you.".localized
        )
    }
}

struct MailContactHotlineType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        let ownerName = SecretCodeProgramPayment<PermanentVIPSecretCodeProgram>.grantedOwnerName ?? PermanentVIPSecretCodeProgram.defaultOwnerName
        return (
                addresses: [papStrings.contact.vip.email]
                , subject: "Hi %@ Team, I'm %@.".localizedFormatted(papStrings.name, ownerName)
                , messageAfterSent: "Thank you %@. Soon we will contact you.".localizedFormatted(ownerName)
        )
    }
}

struct MailContactL10NType:MailContactType{

    private struct StringsResource {
        let bundleName:String

        var baseURL:URL?{
            return Bundle.main.url(forResource: bundleName, withExtension: "strings", subdirectory: nil, localization: "Base")
        }

        var currentURL:URL?{
            if let lang = Locale.preferredLanguages.first{
                return Bundle.main.url(forResource: bundleName, withExtension: "strings", subdirectory: nil, localization: Locale(identifier: lang).languageCode)
            }
            return Bundle.main.url(forResource: bundleName, withExtension: "strings", subdirectory: nil, localization: "Base")
        }
    }

    private static var stringsResources:[StringsResource]{
        return [
            StringsResource(bundleName: "Localizable")
            , StringsResource(bundleName: "Intents")
        ]
    }

    static var attributes: MailContactTypeAttributes{
        return (
                addresses: [papStrings.youapp.l10n.email]
                , subject: "[Locale: \(Locale.preferredLanguages.first ?? "unknown"), Version: \(Bundle.main.version ?? "0")] Applying my localization works. Please confirm!"
                , messageAfterSent: "Thank you very much for share your language talent to us. We will contact you with review result."
        )
    }

    static func prepareMessage(_ asyncSignal: AsyncWaitSignalable) -> (content: String, isHTML: Bool)? {

        var content:String = ""

        for r in stringsResources{
            if let urlOfBase = r.baseURL{
                asyncSignal.begin()

                DispatchQueue.global().async{
                    var stringsDictCurrent:[String:String]? = nil

                    if let urlOfCurrent = r.currentURL{
                        stringsDictCurrent = NSDictionary(contentsOf: urlOfCurrent) as? [String: String]
                    }

                    if let stringsDictBase = NSDictionary(contentsOf: urlOfBase) as? [String: String]{
                        for s in stringsDictBase{
                            content += s.value
                            content += "\n"
                            content += "= \(stringsDictCurrent?[s.key] ?? "")"
                            content += "\n"
                            content += "\n"
                            content += "\n"
                        }
                    }

                    asyncSignal.end()
                }

                asyncSignal.waitUntilEnd()
            }
        }

        return content.count > 0 ? (content:content, isHTML:false) : nil
    }
}
