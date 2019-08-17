//
//  RouteAnalyzer.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation

internal final class RouteAnalyzer {

    private enum RouteEvent {
        case reachedStart, reachedEnd, moved
    }

    var currentSegment: Segment?

    private var analysisTimer: Timer?

    private var currentRoute: Route?

    private var currentState: NavigationState

    private let locationClient: LocationClient

    private let route: DetailedRoute

    private let routeAnalysisHandler: (NavigationState, NavigationGuidance) -> ()

    init(locationClient: LocationClient, route: DetailedRoute, routeAnalysisHandler: @escaping (NavigationState, NavigationGuidance) -> ()) {
        self.locationClient = locationClient
        self.route = route
        self.routeAnalysisHandler = routeAnalysisHandler
        currentState = .navigatingToStartPoint(route.reachStartRegion)
    }

    func start() {
        analysisTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(analyze), userInfo: nil, repeats: true)
        analysisTimer?.fire()
    }

    func stop() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }

    @objc private func analyze() {
        switch currentState {
        case .navigatingToStartPoint:
            let reachedStart = handleReachingStart()
            if reachedStart {
                let location = nearestAlignedLocation()
                currentState = .navigating(location, location.navigationRegion)
                routeAnalysisHandler(currentState, .continueStraight)
            } else {
                routeAnalysisHandler(currentState, .reachStart)
            }
        case .navigating, .offRoute:
            let location = nearestAlignedLocation()
            let distance = location.distanceTo(locationClient.currentLocation)
            let guidance: NavigationGuidance
            if distance <= 50 {
                currentState = .navigating(location, location.navigationRegion)
                guidance = nearestGuidance()
            } else if distance > 100 && distance < 200  {
                currentState = .offRoute(.soft, location, location.navigationRegion)
                guidance = nearestGuidance()
            } else {
                currentState = .offRoute(.hard, locationClient.currentLocation, locationClient.currentLocation.navigationRegion)
                guidance = .rerouting
            }
            routeAnalysisHandler(currentState, guidance)
        case .navigatingToEndPoint:
            break
        }
    }

    private func handleReachingStart() -> Bool {
        let currentLocation = locationClient.currentLocation
        let filtered = route.routes.filter {
            return $0.startPoint.distanceTo(currentLocation) < 10
        }
        return !filtered.isEmpty
    }

    private func nearestAlignedLocation() -> CLLocationCoordinate2D {
        let currentLocation = locationClient.currentLocation
        let sortedRoutes = route.routes.sorted { route1, route2 -> Bool in
            let firstLocationToStart = route1.startPoint.distanceTo(currentLocation)
            let firstLocationToEnd = route1.endPoint.distanceTo(currentLocation)
            let secondLocationToStart = route2.startPoint.distanceTo(currentLocation)
            let secondLocationToEnd = route2.endPoint.distanceTo(currentLocation)
            let firstRouteWeight = (firstLocationToStart + firstLocationToEnd) / Double(route1.length)
            let secondRouteWeight = (secondLocationToStart + secondLocationToEnd) / Double(route2.length)
            return firstRouteWeight < secondRouteWeight
        }
        guard let firstRoute = sortedRoutes.first else { return route.startLocation.location }
        currentRoute = firstRoute
        let sortedSegments = firstRoute.segments.sorted { segment1, segment2 in
            let firstLocationToStart = segment1.start.distanceTo(currentLocation)
            let firstLocationToEnd = segment1.end.distanceTo(currentLocation)
            let secondLocationToStart = segment2.start.distanceTo(currentLocation)
            let secondLocationToEnd = segment2.end.distanceTo(currentLocation)
            let firstSegmentWeight = firstLocationToStart + firstLocationToEnd
            let secondSegmentWeight = secondLocationToStart + secondLocationToEnd
            return firstSegmentWeight < secondSegmentWeight
        }
        guard let firstSegment = sortedSegments.first else { return firstRoute.startPoint }
        currentSegment = firstSegment
        let latitudeDiff = firstSegment.start.latitude - firstSegment.end.latitude
        let longitudeDiff = firstSegment.start.longitude - firstSegment.end.longitude
        guard longitudeDiff != 0, latitudeDiff != 0 else { return firstSegment.start }
        let latitudeChunk = latitudeDiff / 20;
        let longitudeChunk = longitudeDiff / 20;
        var distances = [(CLLocationCoordinate2D, Double)]()
        for index in 0..<20 {
            let chunkedLatitude = firstSegment.start.latitude + (latitudeChunk * Double(index))
            let chunkedLongitude = firstSegment.start.longitude + (longitudeChunk * Double(index))
            let chunkedLocation = CLLocationCoordinate2D(latitude: chunkedLatitude, longitude: chunkedLongitude)
            let distance = chunkedLocation.distanceTo(currentLocation)
            distances.append((chunkedLocation, distance))
        }
        let sortedDistances = distances.sorted { locationData1, locationData2 -> Bool in
            return locationData1.1 < locationData2.1
        }
        guard let firstAligned = sortedDistances.first else { return firstSegment.start }
        return firstAligned.0
    }

    private func nearestGuidance() -> NavigationGuidance {
        let nextSegments = nextTenSegments()
        guard let currentSegment = currentSegment, !nextSegments.isEmpty else { return .continueStraight }
        guard !nextSegments.isEmpty else {
            return .continueStraight
        }
        guard nextSegments.count >= 10 else {
            return .reachingEnd(nextSegments.count * 20)
        }
        var distance = currentSegment.length
        for segment in nextSegments {
            distance = distance + segment.length;
            let headingDiff = currentSegment.heading - segment.heading
            // Avoiding heading diff above or below 170 to overcome the bug with some reversed segments.
            if headingDiff < -60 && headingDiff < 170 {
                return .turnRight(distance)
            } else if headingDiff > 60 && headingDiff > -170 {
                return .turnLeft(distance)
            }
        }
        return .continueStraight
    }

    private func nextTenSegments() -> [Segment] {
        guard let currentRoute = currentRoute, let currentSegment = currentSegment else { return [] }
        var segments = [Segment]()
        if let indexInCurrentRoute = currentRoute.segments.index(where: { $0 == currentSegment }) {
            let segmentsInCurrentRoute = currentRoute.segments.suffix(from: indexInCurrentRoute)
            segments.append(contentsOf: segmentsInCurrentRoute)
        }
        if var indexOfCurrentRoute = route.routes.index(where: { $0 == currentRoute }) {
            indexOfCurrentRoute += 1;
            while segments.count <= 10 {
                if indexOfCurrentRoute == route.routes.count - 1 {
                    return segments
                }
                let nextRoute = route.routes[indexOfCurrentRoute];
                if nextRoute.segments.count >= 10 - segments.count {
                    segments.append(contentsOf: nextRoute.segments.prefix(upTo: 10 - segments.count))
                } else {
                    segments.append(contentsOf: nextRoute.segments)
                }
                indexOfCurrentRoute += 1;
            }
        }
        return segments
    }
}
