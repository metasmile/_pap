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


private struct VisionTextNSTextCheckingResults {
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
        return rawText.emailAddresses().nilEmpty
    }
}

public struct VisionTextDateParser: VisionTextParser{
    typealias OutputType = [Date]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResults.detect(input, NSTextCheckingResult.CheckingType.date)?.compactMap { result -> Date? in
            return result.date
        }.nilEmpty
    }
}

public struct VisionTextURLParser: VisionTextParser{
    typealias OutputType = [URL]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResults.detect(input, NSTextCheckingResult.CheckingType.link)?.compactMap { result -> URL? in
            return result.url
        }.nilEmpty
    }
}

public struct VisionTextAddressParser: VisionTextParser{
    typealias OutputType = [NSTextCheckingAddressComponent]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResults.detect(input, NSTextCheckingResult.CheckingType.address)?.compactMap { result -> NSTextCheckingAddressComponent? in
            return result.address
        }.nilEmpty
    }
}

//https://flightaware.com/live/findflight?origin=EDDF&destination=KLAX
public struct VisionTextFlightInformationParser: VisionTextParser{
    typealias OutputType = [NSTextCheckingFlightComponent]

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return VisionTextNSTextCheckingResults.detect(input, NSTextCheckingResult.CheckingType.transitInformation)?.compactMap { result -> NSTextCheckingFlightComponent? in
            return result.flight
        }.nilEmpty
    }
}

