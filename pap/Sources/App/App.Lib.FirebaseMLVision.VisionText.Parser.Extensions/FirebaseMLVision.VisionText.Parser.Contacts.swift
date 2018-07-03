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
    typealias OutputType = [String]

    private let blockParser = VisionTextTextBlockParser()
    private var regexPattern = "^([A-Z]{2}|[A-Z]\\d|\\d[A-Z])[1-9](\\d{1,3})?$"

    func parse(input: VisionText) -> OutputType? {
        guard let lines = blockParser.parse(input: input) else {
            return nil
        }

        var flightNumbers = [String]()
        for word in lines.reduce([],+){
            let matchedStrings = word.remove(" ").regexStrings(with: regexPattern).reduce([],+)
            flightNumbers.append(contentsOf: matchedStrings)
        }

        return flightNumbers
    }

}

public struct VisionTextContactParser: VisionTextParser, MergingParser{
    typealias OutputType = CNMutableContact

    private static let defaultTypes:NSTextCheckingResult.CheckingType = [.link, .address, .phoneNumber, .date, .quote, .transitInformation]

    public var types:NSTextCheckingResult.CheckingType?

    public var parseLinkAsEmailAddress = true

    func parse(input: FirebaseMLVision.VisionText, mergingOutput: CNMutableContact) -> CNMutableContact? {
        let stringParser = VisionTextStringParser()
        guard let rawText = stringParser.parse(input: input) else{
            return nil
        }

        let contact = mergingOutput

        if let emails = VisionTextEmailAddressParser.parse(string: rawText){
            let label:String = "E-mail Address".localized
            for email in emails{
                let value = CNLabeledValue(label: contact.emailAddresses.count==0 ? label : "\(label) (\(contact.emailAddresses.count))", value: email as NSString)
                contact.emailAddresses.append(value)
            }
        }

        if let phoneNumbers = VisionTextPhoneNumberParser().parse(input: input){
            let label:String = "Phone Number".localized
            for number in phoneNumbers{
                let value = CNLabeledValue(label: contact.phoneNumbers.count==0 ? label : "\(label) (\(contact.phoneNumbers.count))", value: CNPhoneNumber(stringValue: number))
                contact.phoneNumbers.append(value)
            }
        }

        let detectedResults = rawText.detectAll(types: types ?? type(of: self).defaultTypes).nilEmpty ?? []

        for result in detectedResults{

            if let date = result.date{
                var calendar = NSCalendar.current
                if let timezone = result.timeZone{
                    calendar.timeZone = timezone
                }
                let unitFlags = Set<Calendar.Component>([.year, .month, .day])
                let components = calendar.dateComponents(unitFlags, from: date as Date)

                let label = "Date".localized
                let value = CNLabeledValue(label: contact.dates.count==0 ? label : "\(label) (\(contact.dates.count))", value: components as NSDateComponents)
                contact.dates.append(value)
            }

            if let url = result.url{
                let addingValue = url.absoluteString as NSString
                if contact.urlAddresses.contains(where:{ $0.value != addingValue}) == false{
                    let label:String = "URL"
                    let value = CNLabeledValue(label: contact.urlAddresses.count == 0 ? label : "\(label) (\(contact.urlAddresses.count))", value: addingValue)
                    contact.urlAddresses.append(value)
                }
            }

            if let comp = result.componentObject{
                contact.jobTitle = comp.jobTitle ?? mergingOutput.jobTitle
                contact.givenName = comp.name ?? mergingOutput.givenName
                contact.organizationName = comp.organization ?? mergingOutput.organizationName

                let address = CNMutablePostalAddress()
                address.state = result.address?.state ?? ""
                address.city = result.address?.city ?? ""
                address.country = result.address?.country ?? ""
                address.street = result.address?.street ?? ""
                address.postalCode = result.address?.zip ?? ""

                let label = "Address".localized
                let value = CNLabeledValue(label: contact.postalAddresses.count == 0 ? label : "\(label) (\(contact.postalAddresses.count))", value: address as CNPostalAddress)
                contact.postalAddresses.append(value)
            }

            if contact.note.count > 0{
                contact.note += "\n"
            }

            if let flightText = result.flight?.formattedString{
                contact.note += "Flight Information".localized + " : " + flightText
                contact.note += "\n\n"
            }

            if !contact.note.contains(rawText){
                contact.note += rawText
            }
        }

        contact.fillNameIfBlanked()

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

//IBAN: http://ht5ifv.serprest.pt/extensions/tools/IBAN/
