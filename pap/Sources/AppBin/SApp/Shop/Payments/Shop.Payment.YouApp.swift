//
// Created by BLACKGENE on 8/22/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

// https://www.surveymonkey.com/mp/mobile-app-feedback-template/

/*

Mail Address collecting -> Product Hunt Register

*/

/*
You app Survey

Email
Twitter ID

How long have you been first app used?

What kind of apps you want? (Multiple Selection) (ex->HiddenRows)

By App Rating

What are PA apps you loved? (Multiple Selection)

Comment (ex->Costomization of rows with text input)

*/

import Foundation
//import Eureka
import UIKit
import PropertyKit
class YouAppProgramPayment:NSObject, PropertyWatchable, PreparablePayable, GADManagerInterestialDelegate{

    required override init() {}

    private var signal:AsyncWaitSignalable?

    static var isEnable: Bool{
        if AppCenter.charge.isPaid(payable: self){
            return true
        }
        return NetworkReachabilityManager(host: "www.google.com")?.isReachable == true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {

    }

    static var action: PayableAction{
        return PayableAction(title: "Join".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

//        var paid = false

//        signal = AsyncSignal()
//
//        asyncSignal.begin()
//
//        DispatchQueue.main.async{
//            let formVC = YouAppFormController()
//            formVC.watch(\.wasDone) { k,v in
//                if v.newValue == true{
//                    //TODO: Register to Cloud
//                    // paid = true
//                    print(formVC.form.values())
//                    asyncSignal.end()
//                }else{
//                    paid = false
//                    asyncSignal.end()
//                }
//            }
//
//            let nVC = UINavigationController(rootViewController: formVC)
//            formVC.navigationItem.title = AppCenter.charge.getCharge(for: type(of: self))?.describable.title
//            UIViewController.present(nVC, animated: true)
//        }
//        asyncSignal.waitUntilEnd()

//        return paid
        return false
    }
}

/*
private class YouAppFormController: FormViewController, PropertyWatchable {

    @objc dynamic
    var wasDone = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelButtonDidTap))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized, style: .done, target: self, action: #selector(self.submitButtonDidTap))

        LabelRow.defaultCellUpdate = { cell, row in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right

        }

        TextRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }

        form
        +++ Section(header: "Your Information", footer: "")

        <<< TextRow() {
            $0.title = "Name".localized
            $0.add(rule: RuleRequired())
            $0.add(rule: RuleMinLength(minLength: 3))
            $0.validationOptions = .validatesOnChange
        }

        <<< TextRow() {
            $0.title = "Email Address".localized
            $0.add(rule: RuleRequired())
            var ruleSet = RuleSet<String>()
            ruleSet.add(rule: RuleRequired())
            ruleSet.add(rule: RuleEmail())
            $0.add(ruleSet: ruleSet)
            $0.validationOptions = .validatesOnChangeAfterBlurred
        }

//        +++ Section(header: "URL Rule", footer: "Options: Validates on change")
//
//        <<< URLRow() {
//            $0.title = "URL Rule"
//            $0.add(rule: RuleURL())
//            $0.validationOptions = .validatesOnChange
//        }
//                .cellUpdate { cell, row in
//                    if !row.isValid {
//                        cell.titleLabel?.textColor = .red
//                    }
//                }


//        +++ Section(header: "MinLength 8 Rule, MaxLength 13 Rule", footer: "Options: Validates on blurred")
//        <<< PasswordRow() {
//            $0.title = "Password"
//            $0.add(rule: RuleMinLength(minLength: 8))
//            $0.add(rule: RuleMaxLength(maxLength: 13))
//        }
//                .cellUpdate { cell, row in
//                    if !row.isValid {
//                        cell.titleLabel?.textColor = .red
//                    }
//                }


//        +++ Section(header: "Should be GreaterThan 2 and SmallerThan 999", footer: "Options: Validates on blurred")
//
//        <<< IntRow() {
//            $0.title = "Range Rule"
//            $0.add(rule: RuleGreaterThan(min: 2))
//            $0.add(rule: RuleSmallerThan(max: 999))
//        }
//                .cellUpdate { cell, row in
//                    if !row.isValid {
//                        cell.titleLabel?.textColor = .red
//                    }
//                }

//        +++ Section(header: "Match field values", footer: "Options: Validates on blurred")
//
//        <<< PasswordRow("password") {
//            $0.title = "Password"
//        }
//        <<< PasswordRow() {
//            $0.title = "Confirm Password"
//            $0.add(rule: RuleEqualsToRow(form: form, tag: "password"))
//        }
//                .cellUpdate { cell, row in
//                    if !row.isValid {
//                        cell.titleLabel?.textColor = .red
//                    }
//                }


        +++ Section(header: "More sophisticated validations UX using callbacks", footer: "")

        <<< TextRow() {
            $0.title = "Required Rule"
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }



        <<< EmailRow() {
            $0.title = "Email Rule"
            $0.add(rule: RuleRequired())
            $0.add(rule: RuleEmail())
            $0.validationOptions = .validatesOnChangeAfterBlurred
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }



        <<< URLRow() {
            $0.title = "URL Rule"
            $0.add(rule: RuleURL())
            $0.validationOptions = .validatesOnChange
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }


        <<< PasswordRow("password2") {
            $0.title = "Password"
            $0.add(rule: RuleMinLength(minLength: 8))
            $0.add(rule: RuleMaxLength(maxLength: 13))
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }


        <<< PasswordRow() {
            $0.title = "Confirm Password"
            $0.add(rule: RuleEqualsToRow(form: form, tag: "password2"))
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }



        <<< IntRow() {
            $0.title = "Range Rule"
            $0.add(rule: RuleGreaterThan(min: 2))
            $0.add(rule: RuleSmallerThan(max: 999))
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
                .onRowValidationChanged { cell, row in
                    let rowIndex = row.indexPath!.row
                    while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                        row.section?.remove(at: rowIndex + 1)
                    }
                    if !row.isValid {
                        for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                            let labelRow = LabelRow() {
                                $0.title = validationMsg
                                $0.cell.height = { 30 }
                            }
                            row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                        }
                    }
                }


        +++ Section()
        <<< ButtonRow() {
            $0.title = "Submit".localized
        }
                .onCellSelection { cell, row in

                    if row.section?.form?.validate().count == 0{
                        self.dismiss(animated: true, completion: {
                            self.wasDone = true
                        })
                    }

                }


    }
    
    @objc func cancelButtonDidTap(sender: Any) {
        dismiss(animated: true, completion: {
            self.wasDone = false
        })
    }
    
    @objc func submitButtonDidTap(sender: Any) {

    }
}
*/
