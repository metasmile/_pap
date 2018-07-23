//
// Created by BLACKGENE on 23.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension OperatingSystemVersion: Equatable, Comparable{
    private var sumValue:Int{
        return majorVersion*100+minorVersion*10+patchVersion
    }

    public static func == (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.sumValue == rhs.sumValue
    }

    public static func <(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool{
        return lhs.sumValue < rhs.sumValue
    }

    public static func <=(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool{
        return lhs.sumValue <= rhs.sumValue
    }

    public static func >=(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool{
        return lhs.sumValue >= rhs.sumValue
    }

    public static func >(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool{
        return lhs.sumValue > rhs.sumValue
    }
}

public struct SemanticVersion {
    //INFO: based on semantic versioning
    // 1.0 -> 1.1 == +1
    // 1.2.2 -> 1.2.4 == +2
    // 1.2.2 -> 2.0 == +1
    // 1.2.2 -> 1.2.0 == -2
    // 1.2.3 -> 1.3.5 == +6
    // 1.2.3 -> 1.0 == -5
    // 1.2.3 -> 0.0 == -6

    static func distance(old:String, new:String) -> Int{
        if old.trimmed.matched("[^0-9.]") || new.trimmed.matched("[^0-9.]"){
            assert(false,"Version string can contain only '.' or numbers.")
            return 0
        }

        var oldr = old.split(separator: ".")
        if oldr.count<2{
            oldr.append("0")
        }

        var newr = new.split(separator: ".")
        if newr.count<2{
            newr.append("0")
        }

        let vl = newr.count-oldr.count
        for _ in [..<Int(abs(vl))]{
            if vl<0{
                newr.append("0")
            }else if vl>0{
                oldr.append("0")
            }
        }

        var dist:Int = 0
        let oldri = oldr.map { Int($0)!}
        let newri = newr.map { Int($0)!}

        for i in 0 ..< Int(max(oldr.count, newr.count)){
            let o = oldri[i]
            let n = newri[i]
            if abs(dist)>0{
                dist>0 ? (dist += n) : (dist -= o)
            }else{
                dist += n - o
            }
        }
        return dist
    }
}