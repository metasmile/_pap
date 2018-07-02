//
// Created by BLACKGENE on 02.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Contacts

extension CNMutableContact{

    @discardableResult
    public func fillNameIfBlanked() -> Bool{
        let isNameEmpty = self.familyName.count == 0
                && self.givenName.count == 0
                && self.nickname.count == 0
                && self.middleName.count == 0

        if isNameEmpty{
            self.givenName = "Contact \(UUID().uuidString.remove("-").prefix(6))"
        }
        return isNameEmpty
    }
}