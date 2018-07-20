//
// Created by BLACKGENE on 20.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import CoreMotion
import UIKit

/*
    Usage:

    UIDeviceMotion.shared.watch(\.{ orientation | angle | absZ }){
        print(UIDeviceMotion.shared.orientation.rawValue)
    }
*/

class UIDeviceMotion: NSObject, KeyPathWatchable {
    public static let `shared` = UIDeviceMotion()

    private lazy var motionQueue = OperationQueue()
    private lazy var motionManager = CMMotionManager()

    @objc dynamic
    public private(set) var orientation = UIDeviceOrientation.unknown

    @objc dynamic
    public private(set) var angle = Double.nan

    @objc dynamic
    public private(set) var absZ = Double.nan

    override init(){
        super.init()
    }

    func startUpdates(interval:TimeInterval=1) {
        guard false==motionManager.isAccelerometerActive && motionManager.isAccelerometerAvailable else{
            return
        }

        self.motionManager.accelerometerUpdateInterval = interval
        self.motionManager.startAccelerometerUpdates(to: motionQueue) { data, error in
            guard let accData = data else{
                return
            }

            let acc = accData.acceleration
            let (x, y, z) = (acc.x, -acc.y, acc.z)
            var _a = .pi/2.0 - atan2(y, x)
            if _a > .pi{
                _a -= 2.0 * .pi;
            }
            let a = _a
            let absZ = fabs(z)
            let pi4 = .pi/4.0


            var device:UIDeviceOrientation
            if absZ > 0.95{
                if z > 0{
                    device = .faceDown
                }else{
                    device = .faceUp
                }
            } else if a > -pi4 && a < pi4{
                device = .portrait

            }else if a < -pi4 && a > -3 * pi4{
                device = .landscapeLeft

            }else if a > pi4 && a < 3 * pi4{
                device = .landscapeRight

            }else{
                device = .portraitUpsideDown
            }

            self.angle = a
            self.absZ = absZ
            self.orientation = device
        }
    }

    func stopUpdates(){
        self.motionManager.stopAccelerometerUpdates()

        self.angle = .nan
        self.absZ = .nan
        self.orientation = .unknown
    }
}