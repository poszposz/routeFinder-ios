//
//  CyclistAnnotation.swift
//  BikeRouteFinder
//

import Foundation
import MapKit

internal final class CyclistAnnotation: NSObject, MKAnnotation {

    dynamic var coordinate: CLLocationCoordinate2D

    var image = UIImage(named: "biker_annotation")

    var imageView: UIImageView?

    var direction = CLLocationDirection(exactly: 0)

    override init() {
        coordinate = CLLocationCoordinate2D.krakowLocation
    }
}
