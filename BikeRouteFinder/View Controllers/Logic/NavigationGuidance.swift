//
//  NavigationGuidance.swift
//  BikeRouteFinder
//

import Foundation
import UIKit.UIImage

enum NavigationGuidance {
    case reachStart, reachEnd, continueStraight, rerouting
    case turnRight(Int)
    case turnLeft(Int)
    case reachingEnd(Int)
}

extension NavigationGuidance {

    static let numberFormatter = LengthFormatter()

    var title: String {
        switch self {
        case .reachStart:
            return "Reach the route start"
        case .reachEnd:
            return "Reach the route end"
        case .continueStraight:
            return "Continue straight"
        case .rerouting:
            return "Rerouting"
        case .turnLeft(let distance):
            return "Turn left in \(NavigationGuidance.numberFormatter.string(fromMeters: Double(distance)))"
        case .turnRight(let distance):
            return "Turn right in \(NavigationGuidance.numberFormatter.string(fromMeters: Double(distance)))"
        case .reachingEnd(let distance):
            return "Reaching end in \(NavigationGuidance.numberFormatter.string(fromMeters: Double(distance)))"
        }
    }

    var icon: UIImage? {
        switch self {
        case .reachStart, .reachEnd, .reachingEnd:
            return nil
        case .continueStraight:
            return UIImage(named: "straight_icon")
        case .rerouting:
            return UIImage(named: "rerouting_icon")
        case .turnLeft:
            return UIImage(named: "turn_left_icon")
        case .turnRight:
            return UIImage(named: "turn_right_icon")
        }
    }
}
