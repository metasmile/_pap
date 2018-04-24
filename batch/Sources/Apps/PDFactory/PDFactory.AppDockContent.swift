//
// Created by BLACKGENE on 23/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit
import TPPDF

private struct SettingsItem {
    enum Keys {
        case sizePreset
        case landscape
        case imagesPerPage
        case scaleMode
        case metadataCaption
    }

    fileprivate var key: Keys
    fileprivate var label:String
    fileprivate var value:Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cell:String
    fileprivate var iconImageName:String?
}

class PDFactoryAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {
    private var defaults = PDFactory.defaults as? PDFactoryDefaults

    private var settings = [SettingsItem]()

    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
//        view.allowsSelection = false
        view.allowsMultipleSelection = false
        view.register(SwitcherCell.self, forCellReuseIdentifier: SwitcherCell.cellId)
        view.register(StepperCell.self, forCellReuseIdentifier: StepperCell.cellId)
        view.register(SegmentedControlCell.self, forCellReuseIdentifier: SegmentedControlCell.cellId)
        view.register(UITableViewPickerCell.self, forCellReuseIdentifier: UITableViewPickerCell.cellId)
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5
        preferences.pinned = false
        return preferences
    }

    var appDock:AppDock?

    func willSetContentView(_ view:UIView, dock:AppDock) {
        appDock = dock
        settings = [
            SettingsItem(
                    key: .sizePreset
                    , label: "Page Size Preset"
                    , value: defaults?.sizePreset ?? PDFPageFormat.a4.label
                    , valueCollection: PDFactorySettings.SizePresets.keys.map { String($0) }
                    , valueHandler: nil
                    , cell: UITableViewPickerCell.cellId
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .landscape
                    , label: "Landscape Mode"
                    , value: defaults?.landscape ?? false
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.landscape = $0 as? Bool ?? false }
                    , cell: SwitcherCell.cellId
                    , iconImageName: R.image.pdFactoryAppIcon.name
            )
            , SettingsItem(
                    key: .imagesPerPage
                    , label: "Max. Images Per Page"
                    , value: defaults?.imagesPerPage ?? 1
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.imagesPerPage = Int($0 as? Double ?? 1) }
                    , cell: StepperCell.cellId
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .metadataCaption
                    , label: "Caption With Metadata"
                    , value: defaults?.metadataCaption ?? false
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.metadataCaption = $0 as? Bool ?? false }
                    , cell: SwitcherCell.cellId
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .scaleMode
                    , label: "Scale To Fit"
                    , value: defaults?.scaleMode ?? PDFactorySettings.ScaleMode.fitPage
                    , valueCollection: PDFactorySettings.ScaleMode.Labels
                    , valueHandler: { self.defaults?.scaleMode = PDFactorySettings.ScaleMode.Labels.valuesArray[$0 as? Int ?? 0] }
                    , cell: SegmentedControlCell.cellId
                    , iconImageName: nil
            )
        ]
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
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

        if let c = cell as? UITableViewPickerCell {
            return c.estimatedHeightForRowSelected
        }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewPickerCell {
            if cell.isExpanded{
                cell.contract(tableView)
            } else{
                appDock?.expandLayoutIfNeeded(reloadContents: nil)
                DispatchQueue.main.async{
                    cell.expand(tableView)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settings[indexPath.item]

        if item.cell == UITableViewPickerCell.cellId, let valueCollection = item.valueCollection as? [String] {
            let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: item.cell) as? UITableViewPickerCell
                    ?? UITableViewPickerCell(type: .default, reuseIdentifier: item.cell)

            cell.values = valueCollection
            cell.delegate = self
            if let value = item.value as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            return cell

        }

        else if item.cell == SwitcherCell.cellId, let value = item.value as? Bool {
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitcherCell.cellId) as! SwitcherCell
            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
            cell.imageView?.image = item.iconImageName?.asUIImage
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if item.cell == StepperCell.cellId, let value = item.value as? Int {
            let cell = tableView.dequeueReusableCell(withIdentifier: StepperCell.cellId) as! StepperCell
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = String(value)
            cell.imageView?.image = item.iconImageName?.asUIImage

            cell.stepper.stepValue = 1
            cell.stepper.minimumValue = 1
            cell.stepper.maximumValue = 60
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = String(Int(value))
                item.valueHandler?(value)

            }
            return cell
        }

        else if item.cell == SegmentedControlCell.cellId, let valueCollection = item.valueCollection as? [String:Int] {

            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentedControlCell.cellId) as! SegmentedControlCell

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImageName?.asUIImage

            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.valuesArray.index(of: item.value as? Int ?? PDFactorySettings.ScaleMode.fitPage) ?? 0
            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell

    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {
        defaults?.sizePreset = cell.values[row]
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
    }
}

extension UITableViewPickerCell {
    static var cellId:String {
        return "UITableViewPickerCell"
    }
}

//TODO: cell by type
private class SwitcherCell: UITableViewCell {
    static var cellId:String {
        return "SwitcherCell"
    }

    private(set) lazy var switcher: UISwitch = {
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

        accessoryView = switcher
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

    private(set) lazy var stepper: UIStepper = UIStepper()

    var didChangeValue: ((Double) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

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


private class SegmentedControlCell: UITableViewCell {
    static var cellId:String {
        return "SegmentedControlCell"
    }

    private(set) lazy var segmentedControl: UISegmentedControl = UISegmentedControl(items: [])

    var didChangeValue: ((Int) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        segmentedControl.addTarget(self, action: #selector(self.valueDidChange), for: .valueChanged)

        accessoryView = segmentedControl

        self.detailTextLabel?.textColor = UIColor.gray
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func valueDidChange(sender: UISegmentedControl) {
        didChangeValue?(sender.selectedSegmentIndex)
    }
}
