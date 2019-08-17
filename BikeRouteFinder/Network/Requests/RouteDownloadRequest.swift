//
//  RouteDownloadRequest.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation

internal struct RouteDownloadRequest: APIRequest {

    typealias ResponseType = DetailedRoute

    var path: String {
        return "/api/routes/findOptimized"
    }

    var query: String? {
        let query = "endLocation=\(end)"
        guard let startCoordinate = startCoordinate else {
            return query + "&startLocation=\(start)"
        }
        return query + "&startLocationLatitude=\(startCoordinate.latitude)&startLocationLongitude=\(startCoordinate.longitude)"
    }

    private let start: String

    private let end: String

    private let startCoordinate: CLLocationCoordinate2D?

    init(start: String, end: String, startCoordinate: CLLocationCoordinate2D? = nil) {
        self.start = start
        self.end = end
        self.startCoordinate = startCoordinate
    }
}

extension RouteDownloadRequest: Encodable {

    func encode(to encoder: Encoder) throws {}
}
