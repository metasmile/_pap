//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

/*
INFO:

Must be maintained atomic process. Do not use class, and additional parsing logic.
*/

import Foundation
import FirebaseMLVision
import Contacts
import PhoneNumberKit

public struct VisionTextResultGroup {
    init(){}

    var phoneNumbers:[VisionTextPhoneNumberParser.OutputType]?
    var emails:[VisionTextEmailAddressParser.OutputType]?
    var addresses:[VisionTextAddressParser.OutputType]?

    var dates:[VisionTextDateParser.OutputType]?
    var urls:[VisionTextURLParser.OutputType]?
    var flights:[VisionTextFlightInformationParser.OutputType]?

    var isFilled:Bool{
        return self.phoneNumbers?.count ?? 0 > 0
                || self.emails?.count ?? 0 > 0
                || self.addresses?.count ?? 0 > 0

                || self.dates?.count ?? 0 > 0
                || self.urls?.count ?? 0 > 0
                || self.flights?.count ?? 0 > 0
    }
}

private struct VisionTextNSTextCheckingResult {
    static func detect(_ visionText: FirebaseMLVision.VisionText, _ types:NSTextCheckingResult.CheckingType) -> [NSTextCheckingResult]? {
        let stringParser = VisionTextStringParser()
        guard let rawText = stringParser.parse(input: visionText) else{
            return nil
        }
        return rawText.detectAll(types: types).nilEmpty
    }
}


public struct VisionTextPhoneNumberParser: VisionTextParser{
    typealias OutputType = [String]

    private static let phoneNumberKit = PhoneNumberKit()

    private let blockParser = VisionTextTextBlockParser()

    func parse(input: FirebaseMLVision.VisionText) -> VisionTextStringElementsParser.OutputType? {
        guard let lines = blockParser.parse(input: input) else{
            return nil
        }

        var phoneNumbers = Set<String>()

        for line in lines{
            for word in line{
                if let phoneNumber = try? VisionTextPhoneNumberParser.phoneNumberKit.parse(word)
                    , phoneNumber.type != .notParsed && phoneNumber.type != .unknown
                    , phoneNumber.numberString.count>0
                    , !phoneNumbers.contains(phoneNumber.numberString) {

                    phoneNumbers.insert(phoneNumber.numberString)
                }
            }
        }

        return Array<String>(phoneNumbers).nilEmpty
    }
}

public struct VisionTextEmailAddressParser: VisionTextParser{
    typealias OutputType = [String]

    private let stringParser = VisionTextStringParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = stringParser.parse(input: input) else{
            return nil
        }
        return type(of: self).parse(string:rawText)
    }

    static func parse(string:String) -> OutputType?{
        return string.emailAddresses().nilEmpty
    }
}

public struct VisionTextDateParser: VisionTextParser{
    typealias OutputType = [Date]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResult.detect(input, NSTextCheckingResult.CheckingType.date)?.compactMap { result -> Date? in
            return result.date
        }.nilEmpty
    }
}

public struct VisionTextURLParser: VisionTextParser{
    typealias OutputType = [URL]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResult.detect(input, NSTextCheckingResult.CheckingType.link)?.compactMap { result -> URL? in
            return result.url
        }.nilEmpty
    }
}

public struct VisionTextAddressParser: VisionTextParser{
    typealias OutputType = [NSTextCheckingAddressComponent]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResult.detect(input, NSTextCheckingResult.CheckingType.address)?.compactMap { result -> NSTextCheckingAddressComponent? in
            return result.address
        }.nilEmpty
    }
}

//https://flightaware.com/live/findflight?origin=EDDF&destination=KLAX
public struct VisionTextFlightInformationParser: VisionTextParser{
    typealias OutputType = [NSTextCheckingFlightComponent]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResult.detect(input, NSTextCheckingResult.CheckingType.transitInformation)?.compactMap { result -> NSTextCheckingFlightComponent? in
            return result.flight
        }.nilEmpty
    }
}

public struct VisionTextContactParser: VisionTextParser, MergingParser{
    typealias OutputType = CNMutableContact

    private static let types:NSTextCheckingResult.CheckingType = [.link, .address, .phoneNumber, .date, .dash, .quote, .transitInformation]

    func parse(input: FirebaseMLVision.VisionText, mergingOutput: CNMutableContact) -> CNMutableContact? {
        let stringParser = VisionTextStringParser()
        guard let rawText = stringParser.parse(input: input) else{
            return nil
        }

        let contact = mergingOutput

        if let emails = VisionTextEmailAddressParser.parse(string: rawText){
            let values = emails.enumerated().compactMap { (e) -> CNLabeledValue<NSString>? in
                return CNLabeledValue(label: "E-mail Address \(e.0)", value: e.1 as NSString)
            }
            contact.emailAddresses.append(contentsOf: values)
        }

        if let phoneNumbers = VisionTextPhoneNumberParser().parse(input: input){
            let values = phoneNumbers.enumerated().compactMap({ (e) -> CNLabeledValue<CNPhoneNumber>? in
                CNLabeledValue(label: "Phone Number \(e.0)", value: CNPhoneNumber(stringValue: e.1))
            })

            contact.phoneNumbers.append(contentsOf: values)
        }

        let detectedResults = rawText.detectAll(types: type(of: self).types).nilEmpty ?? []

        for result in detectedResults{

            if let date = result.date{
                var calendar = NSCalendar.current
                if let timezone = result.timeZone{
                    calendar.timeZone = timezone
                }
                let unitFlags = Set<Calendar.Component>([.year, .month, .day])
                let components = calendar.dateComponents(unitFlags, from: date as Date)

                contact.dates.append(CNLabeledValue(label: "Date".localized, value: components as NSDateComponents))
                //TODO: result.duration
            }

            if let url = result.url{
                let addingValue = CNLabeledValue(label: "URL", value: url.absoluteString as NSString)

                if contact.urlAddresses.contains(where:{ $0.value != addingValue.value}) == false{
                    contact.urlAddresses.append(addingValue)
                }
            }

            if let comp = result.componentObject{
                contact.jobTitle = comp.jobTitle ?? mergingOutput.jobTitle
                contact.middleName = comp.name ?? mergingOutput.middleName
                contact.organizationName = comp.organization ?? mergingOutput.organizationName

                let address = CNMutablePostalAddress()
                address.state = result.address?.state ?? ""
                address.city = result.address?.city ?? ""
                address.country = result.address?.country ?? ""
                address.street = result.address?.street ?? ""
                address.postalCode = result.address?.zip ?? ""

                contact.postalAddresses.append(CNLabeledValue(label: "Address".localized, value: address))
            }

            if contact.note.count > 0{
                contact.note += "\n\n"
            }

            if let flightText = result.flight?.stringExpression{
                contact.note += "Flight Information".localized + " : " + flightText
                contact.note += "\n"
            }

            if contact.note.count > 0{
                contact.note += "\n"
            }

            contact.note += rawText
        }

        return contact
    }

    func parse(input: FirebaseMLVision.VisionText) -> CNMutableContact? {
        let contact = CNMutableContact()
        contact.contactType = .person

        return self.parse(input: input, mergingOutput: contact)
    }
}

//https://github.com/danthorpe/Money

public struct VisionTextCurrencyParser: VisionTextParser{
    typealias OutputType = [Any]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return nil
    }
}
