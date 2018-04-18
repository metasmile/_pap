//
// Created by BLACKGENE on 16/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

private protocol ExifGhostAppDefaults: AppDefaults{
    var ghostedImageMetadataCollection: ImageMetadataPropertyCollection {get set}
}

extension ExifGhostAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:String, _ property:String){
        guard ImageMetadata.PropertyApple.supportedDictionaries.contains(dictionary) else{
            assert(false, "\(dictionary) is not supported dictionary")
            return
        }

        var immutableSelf = self
        if immutableSelf.ghostedImageMetadataCollection[dictionary] == nil{
            immutableSelf.ghostedImageMetadataCollection = ImageMetadataPropertyCollection()
            var p = immutableSelf.ghostedImageMetadataCollection
            p[dictionary] = [property]
            immutableSelf.ghostedImageMetadataCollection = p
        }else{
            if ghostedImageMetadataCollection[dictionary]?.contains(property) == false{
                var p = immutableSelf.ghostedImageMetadataCollection
                p[dictionary]?.append(property)
                immutableSelf.ghostedImageMetadataCollection = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:String, _ property:String){
        guard ImageMetadata.PropertyApple.supportedDictionaries.contains(dictionary) else{
            assert(false, "\(dictionary) is not supported dictionary")
        }

        if let index = ghostedImageMetadataCollection[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.ghostedImageMetadataCollection
            p[dictionary]?.remove(at: index)
            immutableSelf.ghostedImageMetadataCollection = p
        }
    }
}

extension Defaults: ExifGhostAppDefaults {
    fileprivate var ghostedImageMetadataCollection: ImageMetadataPropertyCollection {
        set{ set(newValue) }
        get{ return get(or: ImageMetadata.Collection.DefaultSensitivity) }
    }
}

private struct MetadataItem{
    fileprivate var key:String
    fileprivate var label:String
}

private struct MetadataDictionary{
    fileprivate var key:String
    fileprivate var label:String
    fileprivate var items:[MetadataItem]
}

class ExifGhostAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private var collection:[MetadataDictionary] = [
        MetadataDictionary(key:ImageMetadata.Dictionary.GPS, label: "GPS",
                items: ImageMetadata.PropertyApple.GPS.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.Labels.GPS[key] ?? key)
                }),

        MetadataDictionary(key:ImageMetadata.Dictionary.Exif, label: "EXIF",
                items: ImageMetadata.PropertyApple.EXIF.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.Labels.Exif[key] ?? key)
                }),

        MetadataDictionary(key:ImageMetadata.Dictionary.TIFF, label: "TIFF",
                items: ImageMetadata.PropertyApple.TIFF.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.Labels.TIFF[key] ?? key)
                })
    ]

    private var initialSelectedIndexPaths:[IndexPath]? = [IndexPath]()

    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
        view.allowsSelection = false
        view.allowsMultipleSelection = false
        view.register(Cell.self, forCellReuseIdentifier: ExifGhost.info.identifier)
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5
        preferences.pinned = false
        return preferences
    }

    var ghostedImageMetadataCollection: ImageMetadataPropertyCollection?{
        return appDefaults?.ghostedImageMetadataCollection
    }

    fileprivate var appDefaults:ExifGhostAppDefaults?{
        return (AppCenter.default.current as? PersistableApp.Type)?.defaults as? ExifGhostAppDefaults
    }

    func didSetContentView(_ view:UIView) {

        if let defaultsCollection = self.appDefaults?.ghostedImageMetadataCollection {
            //sort ascending for handling exif properties
            self.collection = self.collection.map { dictionary -> MetadataDictionary in
                if let handledItems = defaultsCollection[dictionary.key]{
                    var dict = dictionary
                    dict.items = dict.items.sorted { item0, item1 in
                        if let i0 = handledItems.index(of:item0.key){
                            if let i1 = handledItems.index(of:item1.key){
                                return i0 > i1
                            }
                            return true
                        }
                        return false
                    }
                    return dict
                }
                return dictionary
            }

            //get indexes
            let sections = self.collection.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
                if let handledItems = defaultsCollection[dictionary.key]{

                    return handledItems.compactMap { key -> IndexPath? in
                        guard let item = dictionary.items.index(where: { item -> Bool in
                            return key == item.key
                        }) else{
                            return nil
                        }
                        return IndexPath(item: item, section: section)
                    }
                }
                return nil
            }


            //init initialSelectedIndexPaths
            for indexPaths in sections{
                initialSelectedIndexPaths?.append(contentsOf: indexPaths)
            }
        }

        (view as! UITableView).reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return collection.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return collection[section].label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection[section].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dict = self.collection[indexPath.section]

        var selected = true
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = false
        }
        if let appDefaults = appDefaults
        , let _ = appDefaults.ghostedImageMetadataCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = false
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ExifGhost.info.identifier) as! Cell
        cell.textLabel?.text = dict.items[indexPath.item].label
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in
            let dict = self.collection[indexPath.section]
            if on{
                self.appDefaults?.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                self.appDefaults?.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            if self.initialSelectedIndexPaths != nil{
                self.initialSelectedIndexPaths = nil
            }
        }
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