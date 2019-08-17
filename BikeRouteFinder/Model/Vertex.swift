//
//  Vertex.swift
//  BikeRouteFinder
//
//  Created by Jan Posz on 02/08/2019.
//  Copyright © 2019 agh. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

internal struct Vertex {

    let id: Int

    let outcomingRoutes: [Route]

    let incomingRoutes: [Route]

    let centerLocation: CLLocationCoordinate2D
}

extension Vertex: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id, outcomingRoutes, incomingRoutes, centerLocation, longitude, latitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        incomingRoutes = try container.decode([Route].self, forKey: .incomingRoutes)
        outcomingRoutes = try container.decode([Route].self, forKey: .outcomingRoutes)
        let locationContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .centerLocation)
        let latitude = try locationContainer.decode(Double.self, forKey: .latitude)
        let longitude = try locationContainer.decode(Double.self, forKey: .longitude)
        centerLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
