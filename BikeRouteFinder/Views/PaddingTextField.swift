//
//  PaddingTextField.swift
//  BikeRouteFinder
//

import UIKit

internal final class PaddingTextField: UITextField {

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + 10,
            y: bounds.origin.y,
            width: bounds.size.width,
            height: bounds.size.height)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.width - 48,
            y: 0,
            width: 48,
            height: bounds.size.height)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}
