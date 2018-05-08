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

        let cell_from = UITableViewActionSheetCellDescriber()
        let cell_to = UITableViewActionSheetCellDescriber()

        cell_from.itemIdentifier = Cells.convertingDirectionFrom.hashValue
        cell_from.label = "Convert From"
        cell_from.valueGetter =  { self.defaults.convertingDirection.from.rawValue }
        cell_from.valueCollection = ConvertApp.getAvailableWorkersNamesFrom(toRawValue:defaults.convertingDirection.to.rawValue)
        cell_from.valueHandler = { value in
            guard let from = value as? String else {
                return
            }

            let availableToList = ConvertApp.getAvailableWorkersNamesTo(fromRawValue:from)

            //update to cell
            let valueUpdatingGetter = cell_to.valueGetter() as? String
            if let containsValue = valueUpdatingGetter, !availableToList.contains(containsValue){
                cell_to.valueGetter = { availableToList.first }
            }

            if let toValue = valueUpdatingGetter, let direction = ConvertApp.getAvailableDirections().first(where:{ direction in
                direction.to.rawValue == toValue && direction.from.rawValue == from
            }){

                cell_to.valueCollection = availableToList
                self.reloadRows(by:Cells.convertingDirectionTo.hashValue)

                self.defaults.convertingDirection = direction
                self.app?.config?.convertingDirectionIdentifier = direction.identifier

            }
        }
        cellDescribers.append(cell_from)


        cell_to.itemIdentifier = Cells.convertingDirectionTo.hashValue
        cell_to.label = "To"
        cell_to.valueGetter =  { self.defaults.convertingDirection.to.rawValue }
        cell_to.valueCollection = ConvertApp.getAvailableWorkersNamesTo(fromRawValue:defaults.convertingDirection.from.rawValue)
        cell_to.valueHandler = { value in
            guard let to = value as? String else {
                return
            }

            let availableFromList = ConvertApp.getAvailableWorkersNamesFrom(toRawValue: to)

            //update to cell
            let valueUpdatingGetter = cell_from.valueGetter() as? String
            if let containsValue = valueUpdatingGetter, !availableFromList.contains(containsValue){
                cell_from.valueGetter = { availableFromList.first }
            }

            if let fromValue = valueUpdatingGetter, let direction = ConvertApp.getAvailableDirections().first(where:{ direction in
                direction.from.rawValue == fromValue && direction.to.rawValue == to
            }){

                cell_from.valueCollection = availableFromList
                self.reloadRows(by:Cells.convertingDirectionFrom.hashValue)

                self.defaults.convertingDirection = direction
                self.app?.config?.convertingDirectionIdentifier = direction.identifier
            }
        }
        cellDescribers.append(cell_to)


        return cellDescribers
    }

    func reloadRows(by itemIdentifier:Int){
        if let index = (self.cellDescribers.index { item in item.itemIdentifier == itemIdentifier }) {
            (self.view as? UITableView)?.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
        }
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