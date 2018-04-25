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
        case imageQuality
    }

    fileprivate var key: Keys
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

class PDFactoryAppDockContent: NSObject, AppDockContent, AppDockDelegate
        , UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {

    fileprivate var defaults = PDFactory.defaults as? PDFactoryDefaults

    fileprivate var settings = [SettingsItem]()

    lazy var view: UIView = UITableView()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5 + 27
        preferences.pinned = false
        return preferences
    }

    var delegate: AppDockDelegate? {
        return self
    }

    func dockWillContract(_ dock: AppDock) {
        (self.view as? UITableView)?.contractAllVisiblePickerCells()
    }

    var appDock:AppDock?

    func willSetContentView(_ view:UIView, dock:AppDock) {
        appDock = dock
        settings = [
            SettingsItem(
                    key: .sizePreset
                    , label: "Page Size Preset"
                    , valueGetter: { () -> String in self.defaults?.sizePreset ?? PDFPageFormat.a4.label }
                    , valueCollection: PDFactorySettings.SizePresets.keysArray
                    , valueHandler: nil
                    , cellDescriber: UITableViewPickerCellDescriber(cellClass:UITableViewPickerCell.self)
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .landscape
                    , label: "Landscape Mode"
                    , valueGetter: { () -> Bool in self.defaults?.landscape ?? false}
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.landscape = $0 as? Bool ?? false }
                    , cellDescriber: UITableViewSwitchCellDescriber(cellClass: UITableViewSwitchCell.self)
                    , iconImageName: R.image.pdFactoryAppIcon.name
            )
            , SettingsItem(
                    key: .metadataCaption
                    , label: "Metadata Caption"
                    , valueGetter: { () -> Bool in self.defaults?.metadataCaption ?? false}
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.metadataCaption = $0 as? Bool ?? false }
                    , cellDescriber: UITableViewSwitchCellDescriber(cellClass: UITableViewSwitchCell.self)
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .imagesPerPage
                    , label: "Max. Images Per Page"
                    , valueGetter: { () -> Int in self.defaults?.imagesPerPage ?? 1}
                    , valueCollection: nil
                    , valueHandler: { self.defaults?.imagesPerPage = Int($0 as? Double ?? 1) }
                    , cellDescriber: UITableViewStepperCellDescriber(cellClass: UITableViewStepperCell.self, minimumValue: 1, maximumValue: 50, stepValue: 1)
                    , iconImageName: nil
            )
            , SettingsItem(
                    key: .scaleMode
                    , label: "Scale To Fit"
                    , valueGetter: { () -> Int in self.defaults?.scaleMode ?? PDFactorySettings.ScaleMode.fitPage}
                    , valueCollection: PDFactorySettings.ScaleMode.Labels
                    , valueHandler: { self.defaults?.scaleMode = PDFactorySettings.ScaleMode.Labels.valuesArray[$0 as? Int ?? 0] }
                    , cellDescriber: UITableViewSegmentControlCellDescriber(cellClass: UITableViewSegmentedControlCell.self)
                    , iconImageName: nil
            )
        ]

        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 44
            view.allowsMultipleSelection = false

            for item in settings{
                let item = item as! SettingsItem
                view.register(item.cellDescriber.cellClass, forCellReuseIdentifier: item.cellDescriber.identifier)
            }
        }
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
                appDock?.expandDockIfNeeded(reloadContents: nil)
                DispatchQueue.main.async{
                    cell.expand(tableView)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settings[indexPath.item] as! SettingsItem

        if let cellDescriber = item.cellDescriber as? UITableViewPickerCellDescriber
            , let valueCollection = item.valueCollection as? [String] {

            let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as? UITableViewPickerCell
                    ?? UITableViewPickerCell(type: .default, reuseIdentifier: cellDescriber.identifier)

            cell.values = valueCollection
            cell.delegate = self
            if let value = item.valueGetter() as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            return cell

        }
        else if let cellDescriber = item.cellDescriber as? UITableViewSwitchCellDescriber, let value = item.valueGetter() as? Bool {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as! UITableViewSwitchCell
            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
            cell.imageView?.image = item.iconImageName?.asUIImage
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item.cellDescriber as? UITableViewStepperCellDescriber, let value = item.valueGetter() as? Int {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as! UITableViewStepperCell
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = String(value)
            cell.imageView?.image = item.iconImageName?.asUIImage

            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = String(Int(value))
                item.valueHandler?(value)

            }
            return cell
        }

        else if let cellDescriber = item.cellDescriber as? UITableViewSegmentControlCellDescriber, let valueCollection = item.valueCollection as? [String:Int] {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as! UITableViewSegmentedControlCell

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImageName?.asUIImage

            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.valuesArray.index(of: item.valueGetter() as? Int ?? PDFactorySettings.ScaleMode.fitPage) ?? 0
            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell

    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
    }
}

extension UITableViewPickerCellDelegate where Self:PDFactoryAppDockContent{

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {
        defaults?.sizePreset = cell.values[row]
    }
}

//TODO: cell by type
private class UITableViewSwitchCell: UITableViewCell {
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

private class UITableViewStepperCell: UITableViewCell {
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


private class UITableViewSegmentedControlCell: UITableViewCell {
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
