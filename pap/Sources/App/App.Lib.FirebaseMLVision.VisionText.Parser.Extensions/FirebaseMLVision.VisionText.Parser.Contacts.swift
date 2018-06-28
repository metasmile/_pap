//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Contacts
import PhoneNumberKit

public struct VisionTextPhoneNumberParser: VisionTextParser{
    typealias OutputType = [String]

    static let shared = VisionTextPhoneNumberParser()

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

    static let shared = VisionTextEmailAddressParser()

    private let stringParser = VisionTextStringParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = stringParser.parse(input: input) else{
            return nil
        }

        return rawText.emailAddresses().nilEmpty
    }
}

public typealias VisionTextAddressParserResult = [NSTextCheckingKey : String]
public struct VisionTextAddressParser: VisionTextParser{
    typealias OutputType = [VisionTextAddressParserResult]

    static let shared = VisionTextAddressParser()

    private let stringParser = VisionTextStringParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = stringParser.parse(input: input) else{
            return nil
        }
        let results = rawText.detectAll(types: NSTextCheckingResult.CheckingType.address.rawValue).compactMap { result -> VisionTextAddressParserResult? in
            return result.addressComponents
        }

        return results.nilEmpty
    }
}



// NSDataDetector
// https://github.com/marmelroy/PhoneNumberKit/blob/master/examples/PhoneBook/Sample/ViewController.swift
// https://developer.apple.com/documentation/contacts
public struct VisionTextContractParser: VisionTextParser{
    typealias OutputType = [Any]

    static let shared = VisionTextContractParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        return nil
    }
}