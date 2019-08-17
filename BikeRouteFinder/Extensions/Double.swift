//
//  Double.swift
//  BikeRouteFinder
//

import Foundation

internal extension Double {

    var radians: Double {
        return self * .pi / 180.0
    }

    var degrees: Double {
        return self * 180.0 / .pi
    }
}
