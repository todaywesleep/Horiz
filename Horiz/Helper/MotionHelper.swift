//
//  MotionHelper.swift
//  Horiz
//
//  Created by Vladislav Erchik on 9.03.21.
//

import Foundation
import CoreMotion

class MotionHelper {
    let motionManager = CMMotionManager()
    
    init() {
        
    }
    
    func getAccelerometerData(interval: TimeInterval = 0.1, motionDataResult: ((_ x: Float, _ y: Float, _ z: Float) -> ())?) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = interval
            motionManager.startAccelerometerUpdates(to: OperationQueue()) { data, error in
                guard let motionResult = motionDataResult, let data = data else { return }
                motionResult(
                    Float(data.acceleration.x),
                    Float(data.acceleration.y),
                    Float(data.acceleration.z)
                )
            }
        }
    }
}
