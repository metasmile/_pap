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
    case convertingDirectionFrom
    case convertingDirectionTo
}

private extension ConvertableDirection{
    var label:String{
        return "\(from.rawValue) To \(to.rawValue)"
    }
}

class ConvertAppDockContent: NSObject, AppDockContent, AppDockDelegate
        , UITableViewDelegate, UITableViewDataSource {

    fileprivate var defaults = ConvertApp.defaults as! ConvertAppDefaults

    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()

    weak var app:ConvertApp?

    required init(app:ConvertApp){
        self.app = app
    }

    lazy var view: UIView = UITableView()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 2 - 2
        preferences.pinned = false
        return preferences
    }

    var delegate: AppDockDelegate? {
        return self
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
    }

    private func createCellDescribers() -> [UITableViewCellDefaultDescribable]{
        var cellDescribers = [UITableViewCellDefaultDescribable]()

//        let convertModeLabels = ConvertApp.supportedWorkers.map { converterType -> String in
//            return converterType.direction.label
//        }

//        let cell0 =  UITableViewPickerCellDescriber()
//        cell0.itemIdentifier = Cells.convertingDirection.hashValue
//        cell0.label = "Convert From"
//        cell0.valueGetter = { self.defaults.convertingDirection.label }
//        cell0.valueCollection = convertModeLabels
//        cell0.valueHandler = { value in
//            if let label = value as? String
//            , let index = convertModeLabels.index(of: label){
//
//                let direction = ConvertApp.supportedWorkers[index].direction
//                self.defaults.convertingDirection = direction
//                self.app?.config?.convertingDirectionIdentifier = direction.identifier
//            }
//        }
//        cellDescribers.append(cell0)


        let convertDirections = ConvertApp.supportedWorkers.map { converterType -> ConvertableDirection in
            return converterType.direction
        }

        let convertFromLabels = Array(Set(convertDirections.map { direction -> String in  direction.from.rawValue }))
        let convertToLabels = Array(Set(convertDirections.map { direction -> String in  direction.to.rawValue }))

        let cell_from = UITableViewActionSheetCellDescriber()
        let cell_to = UITableViewActionSheetCellDescriber()

        cell_from.itemIdentifier = Cells.convertingDirectionFrom.hashValue
        cell_from.label = "Convert From"
        cell_from.valueGetter =  { self.defaults.convertingDirection.from.rawValue }
        cell_from.valueCollection = convertFromLabels
//        cell0.valuePresenter = { value in
//            if let direction = value as? ConvertableDirection {
//                return direction.from.rawValue
//            }
//            return ""
//        }
        cell_from.valueHandler = { value in
            if let from = value as? String, let to = cell_to.valueGetter() as? String {

                if let direction = convertDirections.first(where:{ direction in
                   direction.to.rawValue==to
                }){

                    self.defaults.convertingDirection = direction
                    self.app?.config?.convertingDirectionIdentifier = direction.identifier

                    cell_to.valueGetter = { direction.to.rawValue }
                    cell_to.valueCollection = convertDirections.compactMap ({ direction -> String? in
                        return direction.from.rawValue == from ? direction.to.rawValue : nil
                    })

                    if let index = (self.cellDescribers.index { item in item.itemIdentifier == Cells.convertingDirectionTo.hashValue }) {
                        (self.view as? UITableView)?.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                    }
                }
            }
        }
        cellDescribers.append(cell_from)

        cell_to.itemIdentifier = Cells.convertingDirectionTo.hashValue
        cell_to.label = "To"
        cell_from.valueGetter =  { self.defaults.convertingDirection.to.rawValue }
        cell_to.valueCollection = convertToLabels
        cell_to.valueHandler = { value in
            if let to = value as? String, let from = cell_from.valueGetter() as? String {

                if let direction = convertDirections.first(where:{ direction in
                    direction.from.rawValue==from
                }){

                    self.defaults.convertingDirection = direction
                    self.app?.config?.convertingDirectionIdentifier = direction.identifier

                    cell_from.valueGetter = { direction.from.rawValue }
                    cell_from.valueCollection = convertDirections.compactMap ({ direction -> String? in
                        return direction.to.rawValue == to ? direction.from.rawValue : nil
                    })

                    if let index = (self.cellDescribers.index { item in item.itemIdentifier == Cells.convertingDirectionFrom.hashValue }) {
                        (self.view as? UITableView)?.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                    }

                }
            }
        }
        cellDescribers.append(cell_to)


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


    func dockWillContract(_ dock: AppDock) {
        (self.view as? UITableView)?.contractAllVisiblePickerCells()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewPickerCell {
            if cell.isExpanded{
                cell.contract(tableView, animated: true) { b in

                }
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
            cell.delegate = self as? UITableViewPickerCellDelegate
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
        else if let cellDescriber = item as? UITableViewActionSheetCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewActionSheetCell {

            cell.textLabel?.text = item.label
            cell.valueLabelText = cellDescriber.presentableValue
            cell.imageView?.image = cellDescriber.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray

            // valuePresenter ->
            if let presenter = cellDescriber.valuePresenter{

                //valueCollection [Any] -> [String]
                if let collection = cellDescriber.valueCollection as? [Any] {
                    cell.valueLabels = collection.map { value -> String in
                        return presenter(value)
                    }
                    cell.valueSelected = { action, index in
                        if let index = index{
                            cellDescriber.valueHandler?(collection[index])
                        }
                    }
                }
            }else{

                // valueCollection -> [String]
                if let collection = cellDescriber.valueCollection as? [String]{
                    cell.valueLabels = collection
                    cell.valueSelected = { action, index in
                        if let index = index{
                            cellDescriber.valueHandler?(collection[index])
                        }
                    }
                }
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
}