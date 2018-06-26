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

    func parse(input: FirebaseMLVision.VisionText) -> VisionTextStringElementsParser.OutputType? {
        guard let lines = VisionTextTextBlockParser.shared.parse(input: input) else{
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

        return Array(phoneNumbers)
    }
}

public struct VisionTextEmailAddressParser: VisionTextParser{
    typealias OutputType = [String]

    static let shared = VisionTextEmailAddressParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = VisionTextStringParser.shared.parse(input: input) else{
            return nil
        }

        return rawText.emailAddresses()
    }
}

public typealias VisionTextAddressParserResult = [NSTextCheckingKey : String]
public struct VisionTextAddressParser: VisionTextParser{
    typealias OutputType = [VisionTextAddressParserResult]

    static let shared = VisionTextAddressParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = VisionTextStringParser.shared.parse(input: input) else{
            return nil
        }
        return rawText.detectAll(types: NSTextCheckingResult.CheckingType.address.rawValue).compactMap { result -> VisionTextAddressParserResult? in
            return result.addressComponents
        }
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