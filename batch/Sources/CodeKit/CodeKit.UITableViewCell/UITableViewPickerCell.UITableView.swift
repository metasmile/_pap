//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UITableView{

    private var allVisiblePickerCells:[(IndexPath, UITableViewPickerCell)]?{
        if let indexes = self.indexPathsForVisibleRows{
            var cells = [(IndexPath, UITableViewPickerCell)]()
            for index in indexes{
                if let pickerCell = self.cellForRow(at: index) as? UITableViewPickerCell{
                    cells.append((index, pickerCell))
                }
            }
            return cells
        }
        return nil
    }

    public func expandAllVisiblePickerCells(completion:(([IndexPath]) -> Swift.Void)? = nil){
        //contract expanded picker cells
        if let cells = allVisiblePickerCells{
            var count = cells.count
            for (index, cell) in cells where cell.isExpanded == false{
                cell.expand(self, animated: true) { _ in
                    count -= 1
                    if count==0{
                        completion?(cells.map { path, _ -> IndexPath in path })
                    }
                }
            }
        }
    }

    public func contractAllVisiblePickerCells(completion:(([IndexPath]) -> Swift.Void)? = nil){
        //contract expanded picker cells
        if let cells = allVisiblePickerCells{
            var count = cells.count
            for (index, cell) in cells where cell.isExpanded == true{
                cell.contract(self, animated: true) { _ in
                    count -= 1
                    if count==0{
                        completion?(cells.map { path, _ -> IndexPath in path })
                    }
                }
            }
        }
    }
}
