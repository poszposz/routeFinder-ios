//
//  UIView.swift
//  BikeRouteFinder
//

import UIKit

internal extension UIView {

    class func autolayoutView() -> Self {
        let view = self.init()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
