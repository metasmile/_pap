//
// Created by BLACKGENE on 16/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

public protocol ExifGhostAppDefaults: AppDefaults{
    var selectedMetadataProperties:[String:[String]] {get set}
}

extension Defaults: ExifGhostAppDefaults {
    public var selectedMetadataProperties: [String:[String]] {
        set{
            set(newValue)
        }
        get{ return get(or:[
            ImageMetadata.Dictionary.GPS: [
                ImageMetadata.Keys.GPSDateStamp
                , ImageMetadata.Keys.GPSDateStamp
                , ImageMetadata.Keys.GPSAltitude
                , ImageMetadata.Keys.GPSAltitudeRef
                , ImageMetadata.Keys.GPSLatitude
                , ImageMetadata.Keys.GPSLatitudeRef
                , ImageMetadata.Keys.GPSLongitude
                , ImageMetadata.Keys.GPSLongitudeRef
                , ImageMetadata.Keys.GPSImgDirection
                , ImageMetadata.Keys.GPSImgDirectionRef

            ],
            ImageMetadata.Dictionary.EXIF: [
                ImageMetadata.Keys.ExifDateTimeDigitized
                , ImageMetadata.Keys.ExifDateTimeOriginal
                , ImageMetadata.Keys.ExifLensMake
                , ImageMetadata.Keys.ExifLensModel
                , ImageMetadata.Keys.ExifLensSerialNumber
                , ImageMetadata.Keys.ExifLensSerialNumber
                , ImageMetadata.Keys.ExifSubsecTime
                , ImageMetadata.Keys.ExifSubsecTimeOriginal
                , ImageMetadata.Keys.ExifSubsecTimeDigitized
            ],
            ImageMetadata.Dictionary.TIFF: [
                ImageMetadata.Keys.TIFFDateTime
                , ImageMetadata.Keys.TIFFArtist
                , ImageMetadata.Keys.TIFFCopyright
                , ImageMetadata.Keys.TIFFDocumentName
                , ImageMetadata.Keys.TIFFSoftware
                , ImageMetadata.Keys.TIFFMake
                , ImageMetadata.Keys.TIFFModel
                , ImageMetadata.Keys.TIFFImageDescription
                , ImageMetadata.Keys.TIFFHostComputer
            ],
        ]) }
    }
}

private struct MetadataItem{
    fileprivate var property:String
    fileprivate var label:String
}

private struct MetadataDictionary{
    fileprivate var property:String
    fileprivate var label:String
    fileprivate var items:[MetadataItem]
}

class ExifGhostAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private let metadataItems:[MetadataDictionary] = [
        MetadataDictionary(property:kCGImagePropertyExifDictionary as String, label: "EXIF",
                items: ImageMetadata.Keys.EXIF.map { key -> MetadataItem in
                    return MetadataItem(property:key, label: ImageMetadata.LabelsForKeys.EXIF[key] ?? key)
                }),

        MetadataDictionary(property:kCGImagePropertyGPSDictionary as String, label: "GPS",
                items: ImageMetadata.Keys.GPS.map { key -> MetadataItem in
                    return MetadataItem(property:key, label: ImageMetadata.LabelsForKeys.GPS[key] ?? key)
                }),

        MetadataDictionary(property:kCGImagePropertyTIFFDictionary as String, label: "TIFF",
                items: ImageMetadata.Keys.TIFF.map { key -> MetadataItem in
                    return MetadataItem(property:key, label: ImageMetadata.LabelsForKeys.TIFF[key] ?? key)
                })
    ]

    var view: UIView{

        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = true
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
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return metadataItems.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return metadataItems[section].label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metadataItems[section].items.count
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "myIdentifier")

        cell.textLabel?.text = metadataItems[indexPath.section].items[indexPath.item].label
        cell.detailTextLabel?.text = "ok. my first UITableView"

        if cell.multipleSelectionBackgroundView == nil{
            cell.multipleSelectionBackgroundView = createSelectedBackgroundView()
        }
        cell.accessoryType = tableView.indexPathsForSelectedRows?.contains(indexPath) == true ? .checkmark : .none
        // cell.accessoryView <- Ghost Icon


        return cell
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
    }
}

