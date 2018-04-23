//
// Created by BLACKGENE on 23/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import DefaultsKit

private struct PDFSettingItem{
    fileprivate var label:String
    fileprivate var valueType:Any.Type
}

class PDFactoryAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private var settings:[PDFSettingItem] = []

    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
        view.allowsSelection = false
        view.allowsMultipleSelection = false
        view.register(Cell.self, forCellReuseIdentifier: PDFactory.info.identifier)
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5
        preferences.pinned = false
        return preferences
    }

    func didSetContentView(_ view:UIView) {


        (view as! UITableView).reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingItem = self.settings[indexPath.section]

        let cell = tableView.dequeueReusableCell(withIdentifier: PDFactory.info.identifier) as! Cell

        cell.textLabel?.text = settingItem.label

//        cell.optionSwitch.setOn(selected, animated: false)
//        cell.switchDidChange = { on in
//            let dict = self.settings[indexPath.section]
//            if on{
//                self.appDefaults?.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
//            }else{
//                self.appDefaults?.addHandledProperty(dict.key, dict.items[indexPath.item].key)
//            }
//
//            if self.initialSelectedIndexPaths != nil{
//                self.initialSelectedIndexPaths = nil
//            }
//        }
        return cell
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
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
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }
}
