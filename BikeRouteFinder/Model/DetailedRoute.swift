//
//  DetailedRoute.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation.CLLocation
import MapKit

internal struct DetailedRoute {

    enum RouteDownloadError: Error {
        case routesEmpty
    }

    let startLocation: DetailedLocation

    let endLocation: DetailedLocation

    let reachStartSegment: Segment

    let reachEndSegment: Segment

    let routes: [Route]
}

extension DetailedRoute: Decodable {

    enum CodingKeys: String, CodingKey {
        case startLocation, endLocation, routes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startLocation = try container.decode(DetailedLocation.self, forKey: .startLocation)
        endLocation = try container.decode(DetailedLocation.self, forKey: .endLocation)
        routes = try container.decode([Route].self, forKey: .routes)
        guard let first = routes.first, let last = routes.last else {
            throw RouteDownloadError.routesEmpty
        }
        reachStartSegment = Segment(start: startLocation.location, end: first.startPoint)
        reachEndSegment = Segment(start: last.endPoint, end: endLocation.location)
    }
}

extension DetailedRoute {

    var routeRegion: MKCoordinateRegion? {
        guard let startingRoute = routes.first, let endingRoute = routes.last else { return nil }
        let startingLocation = startingRoute.startPoint
        let endingLocation = endingRoute.endPoint
        let offset = 0.02;
        let latitudeSpan = abs(startingLocation.latitude - endingLocation.latitude) + offset
        let longitudeSpan = abs(startingLocation.longitude - endingLocation.longitude) + offset
        let latitudeAverage = (startingLocation.latitude + endingLocation.latitude) / 2
        let longitudeAverage = (startingLocation.longitude + endingLocation.longitude) / 2
        let averageLocation = CLLocationCoordinate2D(latitude: latitudeAverage, longitude: longitudeAverage)
        let region = MKCoordinateRegion(center: averageLocation, span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan))
        return region
    }

    var reachStartRegion: MKCoordinateRegion {
        let offset = 0.002;
        let latitudeSpan = abs(reachStartSegment.start.latitude - reachStartSegment.end.latitude) + offset
        let longitudeSpan = abs(reachStartSegment.start.longitude - reachStartSegment.end.longitude) + offset
        let latitudeAverage = (reachStartSegment.start.latitude + reachStartSegment.end.latitude) / 2
        let longitudeAverage = (reachStartSegment.start.longitude + reachStartSegment.end.longitude) / 2
        let averageLocation = CLLocationCoordinate2D(latitude: latitudeAverage, longitude: longitudeAverage)
        let region = MKCoordinateRegion(center: averageLocation, span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan))
        return region
    }

    var reachEndRegion: MKCoordinateRegion {
        let offset = 0.002;
        let latitudeSpan = abs(reachEndSegment.start.latitude - reachEndSegment.end.latitude) + offset
        let longitudeSpan = abs(reachEndSegment.start.longitude - reachEndSegment.end.longitude) + offset
        let latitudeAverage = (reachEndSegment.start.latitude + reachEndSegment.end.latitude) / 2
        let longitudeAverage = (reachEndSegment.start.longitude + reachEndSegment.end.longitude) / 2
        let averageLocation = CLLocationCoordinate2D(latitude: latitudeAverage, longitude: longitudeAverage)
        let region = MKCoordinateRegion(center: averageLocation, span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan))
        return region
    }
}
