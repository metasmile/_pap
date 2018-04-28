//
// Created by BLACKGENE on 19/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ImageMetadata{
    private static let VoidDateFormatter = DateFormatter()
    private static let VoidDateTimeFormats = [
        "yyyy:MM:dd hh:mm:ss": "0000:00:00 00:00:00",
        "yyyy:MM:dd": "0000:00:00",
        "hh:mm:ss":"00:00:00"
    ]
    private static let VoidDirectionValues = [
        "W":"E", "E":"W", "N":"S", "S":"N"
    ]
    private static let VoidTimeStamp = "00:00:00"
    private static let VoidSingleUpperCaseString = "X"
    private static let VoidAnyString = "-"

    static func getVoidValue(_ value:Any) -> Any?{
        if value is Double{
            return Double()
        }
        if value is Float{
            return Float()
        }
        if value is Int{
            return 0
        }
        if value is String{
            let val = value as! String

            // null timestamp
            if val == VoidTimeStamp{
                return val
            }

            // date
            for (format, _) in VoidDateTimeFormats {
                VoidDateFormatter.dateFormat = format
                if let _ = VoidDateFormatter.date(from: val){
                    return VoidDateFormatter.string(from: Date(timeIntervalSince1970: 0))
                }
            }

            // check uppercase and single
            if val.count==1 && val != val.lowercased(){
                if VoidDirectionValues[val] == nil{
                    return VoidSingleUpperCaseString
                }else{
                    return VoidDirectionValues[val]
                }
            }

            return VoidAnyString
        }
        if value is NSArray{
            let val = value as! NSArray

            // fill void value
            if val.count>0{
                return val.compactMap { element -> Any? in
                    return getVoidValue(element)
                }
            }

            return NSArray()
        }
        if value is NSDictionary{
            let val = value as! NSDictionary

            if let keys = val.allKeys as? [NSCopying]{
                return NSDictionary(objects: val.allValues.compactMap { value -> Any? in
                    return getVoidValue(value)
                }, forKeys: keys)
            }
            return [VoidAnyString:VoidAnyString]
        }

        print("[i] Void value is not defined yet: ")
        return nil
    }

    static func isValueVoid(_ value:Any) -> Bool{
        if let voidValue = getVoidValue(value){
            if isEqualAny(type: Double.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Float.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Int.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: String.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Date.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: NSArray.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: NSDictionary.self, value1: voidValue, value2: value){}
            else{
                return false
            }
            return true
        }
        return false
    }
}
