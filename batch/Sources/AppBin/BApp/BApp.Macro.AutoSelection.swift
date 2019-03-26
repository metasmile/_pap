//
// Created by BLACKGENE on 31.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

//INFO: Macros, Case by case

extension AppDockContent {

    func startSelectionBotIconAnimation(_ cellDescribers: [UITableViewCellDefaultDescribable], _ itemIdentifier: Int, _ sectionIndex: Int = 0, _ interval: TimeInterval = 0.4) {
        self.startTableViewCellIconAnimation(R.image.commonCellIconRobot.name, R.image.commonCellIconRobotActive.name, cellDescribers, itemIdentifier, sectionIndex, interval)
    }

    func stopSelectionBotIconAnimation(_ cellDescribers: [UITableViewCellDefaultDescribable], _ itemIdentifier: Int, _ sectionIndex: Int = 0, _ interval: TimeInterval = 0.4) {
        self.stopTableViewCellIconAnimation(R.image.commonCellIconRobot.name, R.image.commonCellIconRobotActive.name, cellDescribers, itemIdentifier, sectionIndex, interval)
    }


    // Common
    func startTableViewCellIconAnimation(_ normalImageName: String, _ animatingImageName: String, _ cellDescribers: [UITableViewCellDefaultDescribable], _ itemIdentifier: Int, _ sectionIndex: Int = 0, _ interval: TimeInterval = 0.4) {
        DispatchQueue.mainAsyncIfNot {
            self.animateTableViewCellIconImage(true, normalImageName, animatingImageName, cellDescribers, itemIdentifier, sectionIndex, interval)
        }
    }

    func stopTableViewCellIconAnimation(_ normalImageName: String, _ animatingImageName: String, _ cellDescribers: [UITableViewCellDefaultDescribable], _ itemIdentifier: Int, _ sectionIndex: Int = 0, _ interval: TimeInterval = 0.4) {
        DispatchQueue.mainAsyncIfNot {
            self.animateTableViewCellIconImage(false, normalImageName, animatingImageName, cellDescribers, itemIdentifier, sectionIndex, interval)
        }
    }

    func animateTableViewCellIconImage(_ start: Bool, _ normalImageName: String, _ animatingImageName: String, _ cellDescribers: [UITableViewCellDefaultDescribable], _ itemIdentifier: Int, _ sectionIndex: Int = 0, _ interval: TimeInterval) {
        assert(DispatchQueue.currentIsMain)

        guard let tableView = (([self.view] + self.view.getAllSubviews()).compactMap{ $0 as? UITableView }).first else {
            return
        }

        let timerId = #function

        if let index = cellDescribers.firstIndex(where: { describable in
            return describable.itemIdentifier == itemIdentifier
        }) {
            var desc = cellDescribers[index]

            let indexPath = IndexPath(item: index, section: sectionIndex)

            if let cell = tableView.dequeueReusableCell(withIdentifier: desc.cellIdentifier) as? UITableViewSwitchCell {

                if start {
                    if Timer.getScheduledTimer(identifier: timerId) == nil {
                        var on = true
                        Timer.scheduledTimer(identifier: timerId, withTimeInterval: interval, repeats: true, block: { timer in
                            cell.switcher.isUserInteractionEnabled = false

                            desc.iconImage = on ? animatingImageName : normalImageName
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [indexPath], with: .none)
                            }, completion: { b in
                                cell.switcher.isUserInteractionEnabled = true
                            })

                            on = !on
                        })
                    }
                } else {
                    cell.switcher.isUserInteractionEnabled = false
                    desc.iconImage = normalImageName
                    tableView.performBatchUpdates({
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }, completion: { b in
                        cell.switcher.isUserInteractionEnabled = true
                    })
                }
            }
        }

        if !start{
            Timer.removeScheduledTimer(identifier: timerId)
        }
    }
}
