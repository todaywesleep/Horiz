//
//  VectorOptions.swift
//  Horiz
//
//  Created by Vladislav Erchik on 10.03.21.
//

import Foundation
import SceneKit

func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

func +=(lhs: inout SCNVector3, rhs: SCNVector3) {
    lhs = lhs + rhs
}
