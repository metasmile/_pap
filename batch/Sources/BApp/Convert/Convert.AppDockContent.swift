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
    case exportQuality
}

private extension ConvertingDirection {
    var label:String{
        return "\(from.rawValue) To \(to.rawValue)"
    }
}

class ConvertAppDockContent: NSObject, AppDockContent, AppDockDelegate
        , UITableViewDelegate, UITableViewDataSource {

    fileprivate var defaults = ConvertApp.defaults as! ConvertAppDefaults

    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()
    fileprivate var cells = [(section: String, items: [UITableViewCellDefaultDescribable], description: String)]()

    weak var app:ConvertApp?

    required init(app:ConvertApp){
        self.app = app
    }

    lazy var view: UIView = UITableView(frame: .zero, style: .grouped)

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 4
        preferences.pinned = false
        return preferences
    }

    var delegate: AppDockDelegate? {
        return self
    }

    var appDock:AppDock?

    func willSetContentView(_ view:UIView, dock:AppDock) {
        appDock = dock

        view.tintColor = UIColor(red:0.99, green:0.51, blue:0.15, alpha:1)

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
        
        let valueCollection = {
            return [
                UIPickerItem(component: "From", values: ConvertApp.availableWorkerNames),
                UIPickerItem(component: "To", values: ConvertApp.getAvailableWorkersNamesTo(fromRawValue:self.defaults.convertingDirection.from.rawValue)),
                ]
        }
        
        let from_to_cell = UITableViewMultiplePickerCellDescriber()
        from_to_cell.itemIdentifier = Cells.convertingDirection.hashValue
        from_to_cell.label = "Convert".localized
        from_to_cell.valueGetter = { (self.defaults.convertingDirection.from, self.defaults.convertingDirection.to) }
        from_to_cell.valueCollection = valueCollection
        from_to_cell.valueHandler = { value in
            guard let value = value as? (UITableViewMultiplePickerCell, Int, String) else { return }
            
            let cell = value.0
            let component = value.1
            let convertTypeRawValue = value.2
            
            if component == 0, let direction = ConvertApp.availableDirections.first(where:{ $0.from.rawValue == convertTypeRawValue }) {
                self.defaults.convertingDirection = direction
                self.app?.config?.convertingDirectionIdentifier = direction.identifier
                
                cell.values = valueCollection()
                cell.picker.reloadComponent(1)
                
                cell.setSelectedRow(cell.values[1].values.index(of: direction.to.rawValue) ?? 0, inComponent: 1, animated: true)
            }
            else if component == 1, let direction = ConvertApp.availableDirections.first(where:{ $0.from == self.defaults.convertingDirection.from && $0.to.rawValue == convertTypeRawValue }) {
                self.defaults.convertingDirection = direction
                self.app?.config?.convertingDirectionIdentifier = direction.identifier
            }
            self.reloadSection(at: 1)
        }
        cellDescribers.append(from_to_cell)
        
        let qualityPresets = [
            ExportQualityType.low,
            ExportQualityType.medium,
            ExportQualityType.high,
            ExportQualityType.original,
        ]
        
        let qualityCollection: (() -> [String]) = {
            var values = qualityPresets
            
            if self.defaults.convertingDirection.from == .livephoto, self.defaults.convertingDirection.to == .mov {
                values = [ExportQualityType.original]
            }
            else {
                switch self.defaults.convertingDirection.to {
                case .gif, .jpeg: values.removeLast()
                default: break
                }
            }
            return values.map { $0.rawValue }
        }
        let qualityCell = UITableViewSegmentControlCellDescriber()
        qualityCell.itemIdentifier = Cells.exportQuality.hashValue
        qualityCell.label = "Quality".localized
        qualityCell.valueCollection = qualityCollection
        qualityCell.valueGetter = { self.defaults.convertingQuality.qualityType.rawValue }
        qualityCell.valueHandler = {
            if let index = $0 as? Int {
                let direction = self.defaults.convertingDirection
                self.defaults.convertingQuality = ConvertingQuality(convertingDirection: direction, qualityType: qualityPresets[index])
            }
        }
        cellDescribers.append(qualityCell)
        
        cells = [
            ("Select Formats to Convert".localized, [from_to_cell], ""/*"From ‣ To".localized*/),
            ("Export Options".localized, [qualityCell], "")
        ]

        return cellDescribers
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        (view as! UITableView).reloadData()
    }
    
    func reloadSection(at section: Int) {
        (self.view as? UITableView)?.reloadSections(IndexSet(integer: section), with: .automatic)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return cells[section].section
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return cells[section].description
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.cellForRow(at: indexPath)

        if let c = cell as? UITableViewExpandableCell {
            return c.estimatedHeightForRowSelected
        }
        return tableView.rowHeight
    }


    func dockWillContract(_ dock: AppDock) {
        (self.view as? UITableView)?.contractAllVisiblePickerCells()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewExpandableCell {
            if cell.isExpanded {
                cell.contract(tableView, animated: true, completion: nil)
            } else{
                tableView.contractAllVisiblePickerCells()
                
                appDock?.expandDockIfNeeded(reloadContents: nil)
                DispatchQueue.main.async{
                    cell.expand(tableView, animated: true, completion: nil)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = cells[indexPath.section].1[indexPath.row]

        if let cellDescriber = item as? UITableViewMultiplePickerCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? (() -> [UIPickerItem])
            , let cell: UITableViewMultiplePickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewMultiplePickerCell{
            
            cell.values = valueCollection()
            if let value = item.valueGetter() as? (ConvertingType, ConvertingType) {
                let row1 = cell.values[0].values.index(where: { $0 == value.0.rawValue }) ?? 0
                let row2 = cell.values[1].values.index(where: { $0 == value.1.rawValue }) ?? 0
                
                cell.setSelectedRow(row1, inComponent: 0, animated: true)
                cell.setSelectedRow(row2, inComponent: 1, animated: true)
                
                cell.valueLabel.text = "\(cell.values[0].values[row1]) ‣ \(cell.values[1].values[row2])"
            }
            cell.titleLabel.text = item.label
            cell.pickerDidChange = { cell, row, component, value in
                cellDescriber.valueHandler?((cell, component, value))
                
                cell.valueLabel.text = "\(cell.values[0].values[cell.selectedRow(for: 0)]) ‣ \(cell.values[1].values[cell.selectedRow(for: 1)])"
            }
            return cell
            
        }
        else if let cellDescriber = item as? UITableViewPickerCellDescriber
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
        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? (() -> [String])
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell {
            
            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray
            
            let values = valueCollection()
            cell.segmentedControl.apportionsSegmentWidthsByContent = true
            cell.segmentedControl.removeAllSegments()
            for k in values {
                cell.segmentedControl.insertSegment(withTitle: k, at: cell.segmentedControl.numberOfSegments, animated: false)
            }
            cell.segmentedControl.sizeToFit()
            
            if let label = item.valueGetter() as? String {
                cell.segmentedControl.selectedSegmentIndex = values.index(of: label) ?? 0
            }
            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }
}
