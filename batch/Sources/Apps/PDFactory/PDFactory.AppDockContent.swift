//
// Created by BLACKGENE on 23/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit
import AUPickerCell

private struct PDFSettingItem{
    fileprivate var label:String
    fileprivate var value:Any
    fileprivate var cell:String
}

class PDFactoryAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, AUPickerCellDelegate{
    private var settings = [
        PDFSettingItem(
                label: "Page Size"
                , value:PDFactorySettings.FormatPresets.keys.map { String($0) }
                , cell: AUPickerCell.cellId
        )
        , PDFSettingItem(
                label: "Land Scape"
                , value:false
                , cell: SwitcherCell.cellId
        )
        , PDFSettingItem(
                label: "Copies Per Page"
                , value:1
                , cell: StepperCell.cellId
        )
    ]

    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
        view.allowsSelection = false
        view.allowsMultipleSelection = false
        view.register(SwitcherCell.self, forCellReuseIdentifier: SwitcherCell.cellId)
        view.register(StepperCell.self, forCellReuseIdentifier: StepperCell.cellId)
        view.register(AUPickerCell.self, forCellReuseIdentifier: AUPickerCell.cellId)
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5
        preferences.pinned = false
        return preferences
    }

    func didSetContentView(_ view:UIView) {
        (view as! UITableView).reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "PDF Export Options"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.cellForRow(at: indexPath)
        if let cell = cell as? AUPickerCell {
            return cell.height
        }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let cell = tableView.dequeueReusableCell(withIdentifier: AUPickerCell.cellId, for: indexPath) as? AUPickerCell {
            cell.selectedInTableView(tableView)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settings[indexPath.item]

        if item.cell == AUPickerCell.cellId, let value = item.value as? [String] {
            var cell:AUPickerCell
            if let c = tableView.dequeueReusableCell(withIdentifier: SwitcherCell.cellId) as? AUPickerCell{
                cell = c
            }else{
                cell = AUPickerCell(type: .default, reuseIdentifier: item.cell)
            }

            cell.values = value
            cell.delegate = self
            cell.selectedRow = 1
            cell.leftLabel.text = item.label
            return cell

        }
        else if item.cell == SwitcherCell.cellId, let value = item.value as? Bool {
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitcherCell.cellId) as! SwitcherCell
            cell.textLabel?.text = item.label
            cell.optionSwitch.setOn(value, animated: false)
            cell.switchDidChange = { on in
                let item = self.settings[indexPath.section]

            }
            return cell
        }

        else if item.cell == StepperCell.cellId, let value = item.value as? Int {
            let cell = tableView.dequeueReusableCell(withIdentifier: StepperCell.cellId) as! StepperCell
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = String(value)
            cell.stepper.value = Double(value)
            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = String(Int(value))
            }
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell

    }

    func auPickerCell(_ cell: AUPickerCell, didPick row: Int, value: Any) {

    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
    }
}

extension AUPickerCell{
    static var cellId:String {
        return "AUPickerCell"
    }
}

//TODO: cell by type
private class SwitcherCell: UITableViewCell {
    static var cellId:String {
        return "SwitcherCell"
    }

    lazy var optionSwitch: UISwitch = {
        let view = UISwitch()
        view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
        return view
    }()

    var switchDidChange: ((Bool) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        switchDidChange = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }
}


private class StepperCell: UITableViewCell {
    static var cellId:String {
        return "StepperCell"
    }

    lazy var stepper: UIStepper = UIStepper()

    var didChangeValue: ((Double) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        stepper.stepValue = 1
        didChangeValue = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        stepper.stepValue = 1
        stepper.minimumValue = 1
        stepper.maximumValue = 60

        stepper.addTarget(self, action: #selector(self.valueDidChange), for: .valueChanged)

        accessoryView = stepper

        self.detailTextLabel?.textColor = UIColor.gray
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func valueDidChange(sender: UIStepper) {
        didChangeValue?(sender.value)
    }
}
