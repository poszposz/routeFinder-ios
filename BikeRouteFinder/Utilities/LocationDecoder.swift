//
//  LocationDecoder.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation
import Contacts

internal final class LocationDecoder {

    private lazy var geocoder = CLGeocoder()

    func reverseGeocodeLocation(_ location: CLLocationCoordinate2D, _ handler: @escaping (String?, Error?) -> ()) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, error in
            guard
                error == nil,
                let placemark = placemarks?.first,
                var streetName = placemark.thoroughfare
            else {
                handler(nil, error)
                return
            }
            if let homeNumber = placemark.subThoroughfare {
                streetName = streetName.whitespaceAppended + homeNumber
            }
            handler(streetName, nil)
        }
    }
}
