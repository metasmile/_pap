//
// Created by BLACKGENE on 23/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit
import TPPDF

private enum Cells {
    case sizePreset
    case landscape
    case imagesPerPage
    case scaleMode
    case metadataCaption
    case imageQuality
    case margin
}

class PDFactoryAppDockContent: NSObject, AppDockContent, AppDockDelegate
        , UITableViewDelegate, UITableViewDataSource {

    fileprivate var defaults = PDFactory.defaults as! PDFactoryDefaults

    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()

    lazy var view: UIView = UITableView()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5 - 2
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

        if cellDescribers.count==0{
            cellDescribers = createCellDescribers()

            if let view = view as? UITableView{
                view.dataSource = self
                view.delegate = self
                view.rowHeight = 44
                view.tintColor = .red
                view.allowsMultipleSelection = false

                for item in cellDescribers {
                    view.register(describer: item)
                }
            }
        }

//            , SettingsItem(
//                    key: .metadataCaption
//                    , label: "Metadata Caption"
//                    , valueGetter: { self.defaults.metadataCaption }
//                    , valueCollection: nil
//                    , valueHandler: { self.defaults.metadataCaption = $0 as? Bool ?? false }
//                    , cellDescriber: UITableViewSwitchCellDescriber()
//                    , iconImageName: nil
//            )

//            , SettingsItem(
//                    key: .imagesPerPage
//                    , label: "Max. Images Per Page"
//                    , valueGetter: { self.defaults.imagesPerPage ?? 1}
//                    , valueCollection: nil
//                    , valueHandler: { self.defaults.imagesPerPage = Int($0 as? Double ?? 1) }
//                    , cellDescriber: UITableViewStepperCellDescriber(cellClass: UITableViewStepperCell.self, minimumValue: 1, maximumValue: 50, stepValue: 1, transformValueLabel:nil)
//                    , iconImageName: nil
//            )
    }

    private func createCellDescribers() -> [UITableViewCellDefaultDescribable]{
        var cellDescribers = [UITableViewCellDefaultDescribable]()

        let cell0 =  UITableViewPickerCellDescriber()
        cell0.itemIdentifier = Cells.sizePreset.hashValue
        cell0.label = "Page Size Preset"
        cell0.valueGetter = { self.defaults.sizePreset }
        cell0.valueCollection = PDFactorySettings.SizePresets.keysArray
        cell0.valueHandler = {
            print($0)
            if let preset = $0 as? String{
                self.defaults.sizePreset = preset
            }
        }
        cellDescribers.append(cell0)

        let cell1 =  UITableViewSegmentControlCellDescriber()
        cell1.itemIdentifier = Cells.landscape.hashValue
        cell1.label = "Layout"
        cell1.valueGetter = { Int(self.defaults.landscape ? 1 : 0) }
        cell1.valueCollection = ["Portrait": 0, "Landscape":1]
        cell1.valueHandler = {
            self.defaults.landscape = ($0 as? Int ?? 0) == 0
        }
        cellDescribers.append(cell1)

        let cell2 =  UITableViewStepperCellDescriber()
        cell2.itemIdentifier = Cells.margin.hashValue
        cell2.label = "Page Margin"
        cell2.valueGetter = { self.defaults.margin }
        cell2.valueHandler = { self.defaults.margin = Int($0 as? Double ?? 10) }
        cell2.minimumValue = 0
        cell2.maximumValue = 80
        cell2.stepValue = 1
        cell2.valuePresenter = UITableViewStepperCellDescriber.percentageAsIntValuePresenter
        cellDescribers.append(cell2)

        let cell3 =  UITableViewStepperCellDescriber()
        cell3.itemIdentifier = Cells.imageQuality.hashValue
        cell3.label = "Image Quality"
        cell3.valueGetter = { Int((self.defaults.imageQuality ) * 100) }
        cell3.valueHandler = {
            self.defaults.imageQuality = (($0 as? Double) ?? 1)/100
        }
        cell3.minimumValue = 60
        cell3.maximumValue = 100
        cell3.stepValue = 2
        cell3.valuePresenter = UITableViewStepperCellDescriber.percentageAsIntValuePresenter
        cellDescribers.append(cell3)

        let cell4 =  UITableViewSegmentControlCellDescriber()
        cell4.itemIdentifier = Cells.scaleMode.hashValue
        cell4.label = "Scale To Fit"
        cell4.valueGetter = { self.defaults.scaleMode }
        cell4.valueCollection = PDFactorySettings.ScaleMode.Labels
        cell4.valueHandler = {
            self.defaults.scaleMode = PDFactorySettings.ScaleMode.Labels.valuesArray[$0 as? Int ?? 0]

            if let index = (self.cellDescribers.index { item in item.itemIdentifier == Cells.margin.hashValue }) {
                (self.view as? UITableView)?.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
            }
        }
        cellDescribers.append(cell4)

        return cellDescribers
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        (view as! UITableView).reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDescribers.count
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
        let item = self.cellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewPickerCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? [String]
            , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewPickerCell{

            cell.values = valueCollection
            if let value = item.valueGetter() as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            cell.didPickHandler = { cell, row, value in
                cellDescriber.valueHandler?(value)
            }
            return cell

        }
        else if let cellDescriber = item as? UITableViewSwitchCellDescriber
            , let value = item.valueGetter() as? Bool
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
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

            // margin
            if item.itemIdentifier == Cells.margin.hashValue && defaults.scaleMode == PDFactorySettings.ScaleMode.fillPage.rawValue{
                cell.textLabel?.isEnabled = false
                cell.detailTextLabel?.isEnabled = false
                cell.stepper.isEnabled = false
                cell.stepper.tintColor = self.view.tintColor.withAlphaComponent(0.3)
                cell.isUserInteractionEnabled = false
            }else{
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = true
                cell.stepper.isEnabled = true
                cell.stepper.tintColor = self.view.tintColor
                cell.isUserInteractionEnabled = true
            }

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(Int(value))
                item.valueHandler?(value)
            }
            return cell
        }

        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? [String:Int]
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

            var values = [(String,Int)]()
            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
                values.append(k)
            }

            cell.segmentedControl.selectedSegmentIndex = values.map{ $0.1 }.index(of: item.valueGetter() as? Int ?? PDFactorySettings.ScaleMode.fitPage.rawValue) ?? 0
            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }
}
