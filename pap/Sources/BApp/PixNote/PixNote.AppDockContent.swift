//
// Created by BLACKGENE on 16/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

private enum SelectionPresets:Int{
    case raw
    case contacts
    case custom
}

private enum Cells {
    case presets
    case autoSelect
    case delete
}

private struct SettingsItem {
    fileprivate var key: Cells
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

private protocol PixNoteAppDefaults: AppDefaults{
    var selectedParserCollection: ParserCollection {get set}
    var selectionPreset: Int {get set}
}

extension Defaults: PixNoteAppDefaults {
    fileprivate var selectedParserCollection: ParserCollection {
        set{ set(newValue) }
        get{ return get(or: Parsers.Collection.Default) }
    }

    fileprivate var selectionPreset: Int {
        set{ set(newValue) }
        get{ return get(or: SelectionPresets.contacts.rawValue ) }
    }
}


extension PixNoteAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:String, _ property:String){

        var immutableSelf = self
        if immutableSelf.selectedParserCollection[dictionary] == nil{
            immutableSelf.selectedParserCollection = ParserCollection()
            var p = immutableSelf.selectedParserCollection
            p[dictionary] = [property]
            immutableSelf.selectedParserCollection = p
        }else{
            if selectedParserCollection[dictionary]?.contains(property) == false{
                var p = immutableSelf.selectedParserCollection
                p[dictionary]?.append(property)
                immutableSelf.selectedParserCollection = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:String, _ property:String){

        if let index = selectedParserCollection[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.selectedParserCollection
            p[dictionary]?.remove(at: index)
            immutableSelf.selectedParserCollection = p
        }
    }
}

public typealias ParserCollection = [String: [String]]

private struct Parsers {

    public struct Collection {

        public static let Default: ParserCollection = [
            Parsers.Dictionary.Contract: [
                Parsers.Property.PhoneNumber
                ,Parsers.Property.EmailAddress
                ,Parsers.Property.Address
                ,Parsers.Property.Date
            ]
        ]
    }


    public struct Dictionary {
        static var Contract:String { return "Contract" }
    }

    public struct Property {
        static let PhoneNumber: String = "PhoneNumber"
        static let EmailAddress: String = "EmailAddress"
        static let Address: String = "Address"
        static let Date: String = "Date"
    }
}

private struct ParserItem {
    fileprivate var key:String
    fileprivate var label:String
//    fileprivate var parser:
}

private struct ParserDictionary {
    fileprivate var key:String
    fileprivate var label:String
    fileprivate var items:[ParserItem]
}

class PixNoteAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()

    private var parserCollection:[ParserDictionary] = [

        ParserDictionary(key: Parsers.Dictionary.Contract, label: "Contract".localized,
                items: [
                    ParserItem(key: Parsers.Property.PhoneNumber, label:"Phone Number".localized)
                    ,ParserItem(key: Parsers.Property.EmailAddress, label:"E-mail Address".localized)
                    ,ParserItem(key: Parsers.Property.Address, label:"Address".localized)
                    ,ParserItem(key: Parsers.Property.Date, label:"Date".localized)
                ])
    ]

    required public override init() {
        super.init()
    }

    private var initialSelectedIndexPaths:[IndexPath]?

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = UIColor(red:0.13, green:0.15, blue:0.16, alpha:1)
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 300
        return preferences
    }

    var selectedParserCollection: ParserCollection{
        return defaults.selectedParserCollection
    }

    var shouldGhostAll:Bool{
        return defaults.selectionPreset == SelectionPresets.raw.rawValue
    }

    private var autoSelect:Bool = false

    fileprivate var defaults:PixNoteAppDefaults = PixNote.defaults as! PixNoteAppDefaults

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if cellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchCellDescriber()
        cell1.itemIdentifier = Cells.autoSelect.hashValue
        cell1.label = "Enable Auto Selection".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.valueHandler = {
            self.autoSelect = $0 as! Bool
            AppCenter.default.currentInstanceAs(PixNote.self)?.autoSelect = self.autoSelect
        }
        cellDescribers.append(cell1)


        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = Cells.presets.hashValue
        cell0.label = "Presets".localized
        cell0.valueGetter = { self.defaults.selectionPreset }
        cell0.valueCollection = [
            (label:"Raw Text",value:SelectionPresets.raw.rawValue),
            (label:"All Contracts",value:SelectionPresets.contacts.rawValue),
            (label:"Custom", value:SelectionPresets.custom.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            self.defaults.selectionPreset = preset

            (view as? UITableView)?.performBatchUpdates({
                if preset == SelectionPresets.raw.rawValue{
                    for m in self.parserCollection {
                        for i in m.items{
                            self.defaults.addHandledProperty(m.key, i.key)
                        }
                    }
                }else if preset == SelectionPresets.contacts.rawValue{
                    for m in self.parserCollection {
                        for i in m.items{
                            self.defaults.removeHandledProperty(m.key, i.key)
                        }
                    }
                    for m in Parsers.Collection.Default{
                        for i in m.value{
                            self.defaults.addHandledProperty(m.key, i)
                        }
                    }
                }

                (view as? UITableView)?.reloadData()
            }, completion:nil)
        }
        cellDescribers.append(cell0)



        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: PixNote.info.identifier)

            for desc in cellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        let defaultsCollection = self.defaults.selectedParserCollection

        //get indexes
        let sections = self.parserCollection.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
            if let handledItems = defaultsCollection[dictionary.key]{

                return handledItems.compactMap { key -> IndexPath? in
                    guard let item = dictionary.items.index(where: { item -> Bool in
                        return key == item.key
                    }) else{
                        return nil
                    }
                    return IndexPath(item: item, section: 1+section)
                }
            }
            return nil
        }


        //init initialSelectedIndexPaths
        initialSelectedIndexPaths = [IndexPath]()
        for indexPaths in sections{
            initialSelectedIndexPaths?.append(contentsOf: indexPaths)
        }

        (view as! UITableView).reloadData()

        initialSelectedIndexPaths = nil
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + parserCollection.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "🖼️ ‣ 🤖 ‣ 😸 " + "Select Photos You Want To Grab!".localized
        return section == 0 ? label_section0 : parserCollection[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? cellDescribers.count : parserCollection[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : parserCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.cellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewPickerCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [String]
        , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewPickerCell {

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
        else if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewStepperCellDescriber
        , let value = item.valueGetter() as? Int
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewStepperCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(Int(value))
                item.valueHandler?(value)
            }
            return cell
        }

        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [(String, Int)]
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.segmentedControl.removeAllSegments()

            for (label, _) in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: label, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.index { t in
                t.1 == (item.valueGetter() as! Int)
            } ?? 0

            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }

    func parserCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dict = self.parserCollection[indexPath.section-1]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let _ = defaults.selectedParserCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PixNote.info.identifier) as! Cell
        cell.textLabel?.text = dict.items[indexPath.item].label
        cell.detailTextLabel?.text = selected ? "will be hided" : nil
//        cell.imageView?.image = selected ? R.image.pdFactoryAppIcon() : nil //selected ? UIImageView(image: R.image.pdFactoryAppIcon()) : nil
        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in
            if on{
                self.defaults.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                self.defaults.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            tableView.reloadRows(at: [indexPath], with: .fade)

            let selectedPreset = self.defaults.selectionPreset

            if selectedPreset == SelectionPresets.raw.rawValue || selectedPreset == SelectionPresets.contacts.rawValue{
                self.defaults.selectionPreset = SelectionPresets.custom.rawValue

                tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }

        }
        return cell
    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {

    }
}

private class Cell: UITableViewCell {
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
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        optionSwitch.onTintColor = tintColor
    }
}
