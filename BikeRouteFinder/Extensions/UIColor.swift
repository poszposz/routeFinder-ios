//
//  UIColor.swift
//  BikeRouteFinder
//

import UIKit

internal extension UIColor {

    class var randomColor: UIColor {
        let redValue = CGFloat(arc4random_uniform(255)) / 255.0;
        let greenValue = CGFloat(arc4random_uniform(255)) / 255.0;
        let blueValue = CGFloat(arc4random_uniform(255)) / 255.0;
        return UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 0.7)
    }
}
