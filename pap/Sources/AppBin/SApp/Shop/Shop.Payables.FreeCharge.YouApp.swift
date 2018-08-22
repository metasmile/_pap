//
// Created by BLACKGENE on 8/22/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class YouAppProgramPayment:NSObject, KeyPathWatchable, PreparablePayable, AdManagerInterestialDelegate{

    required override init() {

    }

    private var signal:AsyncWaitSignalable?

    static var isEnable: Bool{
        if AppCenter.charge.isPaid(payable: self){
            return true
        }
        return NetworkReachabilityManager(host: "www.google.com")?.isReachable == true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {

    }

    static var label: String {
        return "Join".localized
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        signal = asyncSignal

        asyncSignal.begin()

        DispatchQueue.main.async{
            let formVC = YouAppFormController()
            formVC.watch(\.wasDone){
                //TODO: Register to Cloud
                print(formVC.form.values())

                asyncSignal.end()
            }

            let nVC = UINavigationController(rootViewController: formVC)
            nVC.title = AppCenter.charge.getCharge(for: type(of: self))?.describable.title
            nVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(self.cancelButtonDidTap))

            UIViewController.root!.present(nVC, animated: true)
        }
        asyncSignal.waitUntilEnd()

        return paid
    }

    @objc func cancelButtonDidTap(sender: Any) {
        while signal?.end().began ?? false {}
    }
}

class YouAppFormController: FormViewController, KeyPathWatchable {

    @objc dynamic
    var wasDone = false

    override func viewDidLoad() {
        super.viewDidLoad()

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
        +++ Section(header: "Required Rule", footer: "Options: Validates on change")

        <<< TextRow() {
            $0.title = "Required Rule"
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
        }


        +++ Section(header: "Email Rule, Required Rule", footer: "Options: Validates on change after blurred")

        <<< TextRow() {
            $0.title = "Email Rule"
            $0.add(rule: RuleRequired())
            var ruleSet = RuleSet<String>()
            ruleSet.add(rule: RuleRequired())
            ruleSet.add(rule: RuleEmail())
            $0.add(ruleSet: ruleSet)
            $0.validationOptions = .validatesOnChangeAfterBlurred
        }

        +++ Section(header: "URL Rule", footer: "Options: Validates on change")

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


        +++ Section(header: "MinLength 8 Rule, MaxLength 13 Rule", footer: "Options: Validates on blurred")
        <<< PasswordRow() {
            $0.title = "Password"
            $0.add(rule: RuleMinLength(minLength: 8))
            $0.add(rule: RuleMaxLength(maxLength: 13))
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }


        +++ Section(header: "Should be GreaterThan 2 and SmallerThan 999", footer: "Options: Validates on blurred")

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

        +++ Section(header: "Match field values", footer: "Options: Validates on blurred")

        <<< PasswordRow("password") {
            $0.title = "Password"
        }
        <<< PasswordRow() {
            $0.title = "Confirm Password"
            $0.add(rule: RuleEqualsToRow(form: form, tag: "password"))
        }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }


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
                    
//                    if row.section?.form?.validate().count == 0{
                        (self.navigationController ?? self).dismiss(animated: true, completion: {
                            self.wasDone = true
                        })
//                    }
                    
                }


    }
}
