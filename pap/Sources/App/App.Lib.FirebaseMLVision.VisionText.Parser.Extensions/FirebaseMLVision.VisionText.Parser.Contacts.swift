//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Contacts
import PhoneNumberKit

public struct VisionTextPhoneNumberParser: VisionTextParser{
    typealias OutputType = VisionTextStringElementsParser.OutputType

    static let shared = VisionTextPhoneNumberParser()
    private let phoneNumberKit = PhoneNumberKit()

    func parse(input: FirebaseMLVision.VisionText) -> VisionTextStringElementsParser.OutputType? {
        guard let lines = VisionTextTextBlockParser.shared.parse(input: input) else{
            return nil
        }

        var phoneNumbers = [String]()

        for line in lines{
            for word in line{
                if let phoneNumber = try? phoneNumberKit.parse(word){
                    phoneNumbers.append(phoneNumber.numberString)
                }
            }
        }

        return phoneNumbers
    }
}

public struct VisionTextEmailAddressParser: VisionTextParser{
    typealias OutputType = VisionTextStringElementsParser.OutputType

    static let shared = VisionTextEmailAddressParser()

    func parse(input: FirebaseMLVision.VisionText) -> OutputType? {
        guard let rawText = VisionTextStringParser.shared.parse(input: input) else{
            return nil
        }

        return rawText.emailAddresses()
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