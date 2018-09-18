//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

typealias MailContactTypeAttributes = (addresses:[String], subject:String)

protocol MailContactType {
    static var attributes: MailContactTypeAttributes {get}
}

struct MailContactFeedbackType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        return (
                addresses: [papStrings.contact.feedback.email]
                , subject: "👋 " + "My Feedback on %@".localizedFormatted(papStrings.name)
        )
    }
}

struct MailContactSupportType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        return (
                addresses: [papStrings.contact.support.email]
                , subject: "[\(UUID().uuidString.split(separator: "-")[0])] I need some help while using this app."
        )
    }
}

struct MailContactHotlineType: MailContactType {
    static var attributes: MailContactTypeAttributes {
        return (
                addresses: [papStrings.contact.vip.email]
                , subject: "Hi! I'm %@, I need some help.".localizedFormatted(SecretCodeProgramPayment<PermanentVIPSecretCodeProgram>.grantedOwnerName ?? "VIP \(UUID().uuidString.split(separator: "-")[0])")
        )
    }
}
