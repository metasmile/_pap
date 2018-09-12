//
// Created by BLACKGENE on 8/24/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


extension RelativePayable{
    static var defaultSuperPayables: HashSet<Payable.Type> {
        let e = HashElement(self as Payable.Type)

        if AllAppsAutoRenewable.contains(e){
            return AllAppsAutoRenewable.subtracting([self].hashSet)
        }

        if AllAppsNonRenewing.contains(e){
            return all.subtracting([self].hashSet)
        }

        return all
    }

    // 1st
    private static var AllAppsAutoRenewable:HashSet<Payable.Type> {
        return [
            AllTimeAllAppsPayment.self,
            PermanentVIPProgramPayment.self,
            MonthlyAllAppsPayment.self,
            YearlyAllAppsPayment.self
        ].hashSet
    }

    // 2nd
    private static var AllAppsNonRenewing:HashSet<Payable.Type> {
        return [
            OneMonthAllAppsPayment.self,
            ThreeMonthsAllAppsPayment.self,
            SixMonthsAllAppsPayment.self,
            OneYearAllAppsPayment.self
        ].hashSet
    }

    private static var all:HashSet<Payable.Type> {
        return AllAppsNonRenewing.union(AllAppsAutoRenewable)
    }
}
