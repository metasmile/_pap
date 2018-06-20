//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Contacts
import PhoneNumberKit

//TODO: parse with ContactsKit Object
public final class VisionTextPhoneNumberParser: VisionTextStringElementsParser{

    private let phoneNumberKit = PhoneNumberKit()

    override func parse(input: FirebaseMLVision.VisionText) -> VisionTextStringElementsParser.OutputType? {
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

public final class VisionTextEmailAddressParser: VisionTextStringElementsParser{
    override func parse(input: FirebaseMLVision.VisionText) -> VisionTextStringElementsParser.OutputType? {
        guard let rawText = VisionTextStringParser.shared.parse(input: input) else{
            return nil
        }

        return rawText.emailAddresses()
    }
}

// NSDataDetector
// https://github.com/marmelroy/PhoneNumberKit/blob/master/examples/PhoneBook/Sample/ViewController.swift
// https://developer.apple.com/documentation/contacts
public class VisionTextContractParser: VisionTextStringParser{}

extension VisionTextContractParser{
    func parse(input: FirebaseMLVision.VisionText) -> CNContact? {
        return nil
    }
}