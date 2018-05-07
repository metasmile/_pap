//
// Created by BLACKGENE on 07/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


import Foundation
import UIKit
import DefaultsKit
import TPPDF

private enum Cells {
    case convertingDirection
}

private extension ConvertableDirection{
    var label:String{
        return "\(from.rawValue) To \(to.rawValue)"
    }
}

class ConvertAppDockContent: NSObject, AppDockContent, AppDockDelegate
        , UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {

    fileprivate var defaults = ConvertApp.defaults as! ConvertAppDefaults

    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()

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

        if cellDescribers.count==0{
            cellDescribers = createCellDescribers()

            if let view = view as? UITableView{
                view.dataSource = self
                view.delegate = self
                view.rowHeight = 44
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

        let convertModeLabels = ConvertApp.supportedWorkers.map { converterType -> String in
            return converterType.direction.label
        }

        let cell0 =  UITableViewPickerCellDescriber()
        cell0.itemIdentifier = Cells.convertingDirection.hashValue
        cell0.label = "Convert From"
        cell0.valueGetter = { self.defaults.convertingDirection.label }
        cell0.valueCollection = convertModeLabels
        cell0.valueHandler = { value in
            if let label = value as? String
            , let index = convertModeLabels.index(of: label){
                self.defaults.convertingDirection = ConvertApp.supportedWorkers[index].direction
            }
        }
        cellDescribers.append(cell0)


        return cellDescribers
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
        , let valueCollection = cellDescriber.valueCollection as? [String:Int]
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.valuesArray.index(of: item.valueGetter() as? Int ?? PDFactorySettings.ScaleMode.fitPage.rawValue) ?? 0
            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {

    }
}