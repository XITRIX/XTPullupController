//
//  DecelerationTimingParameters.swift
//  PullupController
//
//  Created by Даниил Виноградов on 12.04.2021.
//

import UIKit

extension CGPoint {
    static prefix func -(lhs: CGPoint) -> CGPoint {
        CGPoint(x: -lhs.x, y: -lhs.y)
    }
    
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }
}

struct DecelerationTimingParameters {
    var initialValue: CGPoint
    var initialVelocity: CGPoint
    var decelerationRate: CGFloat
    var threshold: CGFloat
    
    var destination: CGPoint {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue - initialVelocity / dCoeff
    }
    
    var duration: TimeInterval {
        guard initialVelocity.length > 0 else { return 0 }
        
        let dCoeff = 1000 * log(decelerationRate)
        return TimeInterval(log(-dCoeff * threshold / initialVelocity.length) / dCoeff)
    }
    
    func value(at time: TimeInterval) -> CGPoint {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue + (pow(decelerationRate, CGFloat(1000 * time)) - 1) / dCoeff * initialVelocity
    }
}
