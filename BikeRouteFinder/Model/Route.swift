//
//  Route.swift
//  BikeRouteFinder
//
//  Created by Jan Posz on 29.07.2018.
//  Copyright © 2018 agh. All rights reserved.
//

import Foundation
import CoreLocation

internal struct Route: Equatable {

    /// An API identifier of the route.
    let id: String
    
    /// The category of the route.
    let category: String

    /// Indicates if the route is one way or bidirectional.
    let isBidirectional: Bool

    /// The name of the route, typically the street name.
    let name: String?
    
    /// A start coordinate of the route.
    let startPoint: CLLocationCoordinate2D
    
    /// An end coordinate of the route.
    let endPoint: CLLocationCoordinate2D
    
    /// Total length of the route.
    let length: Int
    
    /// All segments a route is composed from.
    let segments: [Segment]

    /// An id of the vertex the route is starting with.
    let startPointVertexId: Int

    /// An id of the vertex the route is ending with.
    let endPointVertexId: Int

    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Route: Decodable {
    
    private enum CodingKeys: CodingKey {
        case id
        case segments
        case totalLength
        case category
        case bidirectional
        case name
        case start
        case end
        case startPointVertexId
        case endPointVertexId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        segments = try container.decode([Segment].self, forKey: .segments)
        startPoint = try container.decode(CLLocationCoordinate2D.self, forKey: .start)
        endPoint = try container.decode(CLLocationCoordinate2D.self, forKey: .end)
        category = try container.decode(String.self, forKey: .category)
        isBidirectional = try container.decode(Int.self, forKey: .bidirectional) == 1 ? true : false
        name = try container.decodeIfPresent(String.self, forKey: .name)
        length = try container.decode(Int.self, forKey: .totalLength)
        startPointVertexId = try container.decode(Int.self, forKey: .startPointVertexId)
        endPointVertexId = try container.decode(Int.self, forKey: .endPointVertexId)
    }
}
