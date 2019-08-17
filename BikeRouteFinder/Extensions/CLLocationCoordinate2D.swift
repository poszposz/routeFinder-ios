//
//  CLLocationCoordinate2D.swift
//  BikeRouteFinder
//
//  Created by Jan Posz on 29.07.2018.
//  Copyright © 2018 agh. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D {

    var navigationRegion: MKCoordinateRegion {
        return MKCoordinateRegion(center: self, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
    }

    func distanceTo(_ location: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return location1.distance(from: location2)
    }

    static var krakowLocation: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 50.062004, longitude: 19.937522)
    }
}

extension CLLocationCoordinate2D: Equatable {

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
