//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Contacts

public final class VisionTextPhoneNumberParser: VisionTextStringParser{
    override func parse(input: FirebaseMLVision.VisionText) -> String? {
        return nil
    }
}

public final class VisionTextEmailAddressParser: VisionTextStringParser{
    override func parse(input: FirebaseMLVision.VisionText) -> String? {
        let rawText = super.parse(input: input)
//        rawText.emailAddresses()
        return nil
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