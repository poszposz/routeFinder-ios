//
//  DetailedLocation.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation.CLLocation

internal struct DetailedLocation {

    let displayName: String

    let location: CLLocationCoordinate2D
}

extension DetailedLocation: Decodable {

    private enum CodingKeys: String, CodingKey {
        case displayName, location, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        let locationContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .location)
        let latitude = try locationContainer.decode(Double.self, forKey: .latitude)
        let longitude = try locationContainer.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
