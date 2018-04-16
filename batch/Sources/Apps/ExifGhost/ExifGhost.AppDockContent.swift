//
// Created by BLACKGENE on 16/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import SwipeCellKit
import UIKit

class ExifGhostAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    var view: UIView{

        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.allowsMultipleSelectionDuringEditing = true
        view.rowHeight = UITableViewAutomaticDimension

        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = 200
        preferences.pinned = false
        return preferences
    }

    func didSetContentView() {
        (self.view as! UITableView).reloadData()
        (self.view as! UITableView).setEditing(true, animated: false)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell = UITableViewCell(style: .subtitle, reuseIdentifier: "myIdentifier")

//        cell.selectedBackgroundView = createSelectedBackgroundView()
        myCell.textLabel?.text = "\(indexPath.row)"
        myCell.detailTextLabel?.text = "ok. my first UITableView"

        return myCell
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        return view
    }
}

