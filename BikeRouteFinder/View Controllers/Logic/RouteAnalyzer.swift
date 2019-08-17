//
//  RouteAnalyzer.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation

internal final class RouteAnalyzer {

    private enum RouteAnalysisContants {
        static let routeAnalysisStepInterval: Double = 1
        static let startingReachRadius: Double = 10
        static let endingReachRadius: Double = 20
        static let turnHeadingDifference: Double = 60
        static let routeAlignmentMaximumDistance: Double = 30
        static let softOffRouteAlignmentMaximumDistance: Double = 50
        static let rerouteDistance: Double = 150
    }

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
        analysisTimer = Timer.scheduledTimer(timeInterval: RouteAnalysisContants.routeAnalysisStepInterval, target: self, selector: #selector(analyze), userInfo: nil, repeats: true)
        analysisTimer?.fire()
    }

    func stop() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }

    @objc private func analyze() {
        switch currentState {
        case .navigatingToStartPoint:
            let reachedStart = checkReachingStart()
            if reachedStart {
                let location = nearestAlignedLocation()
                currentState = .navigating(location, location.navigationRegion)
                routeAnalysisHandler(currentState, .continueStraight)
            } else {
                routeAnalysisHandler(currentState, .reachStart)
            }
        case .navigating, .offRoute:
            guard !checkReachingEnd() else {
                currentState = .navigatingToEndPoint(route.reachEndRegion)
                routeAnalysisHandler(currentState, .reachEnd)
                return
            }
            let location = nearestAlignedLocation()
            let distance = location.distanceTo(locationClient.currentLocation)
            let guidance: NavigationGuidance
            if distance <= RouteAnalysisContants.routeAlignmentMaximumDistance {
                currentState = .navigating(location, location.navigationRegion)
                guidance = nearestGuidance()
            } else if distance > RouteAnalysisContants.routeAlignmentMaximumDistance && distance < RouteAnalysisContants.softOffRouteAlignmentMaximumDistance  {
                currentState = .offRoute(.soft, location, location.navigationRegion)
                guidance = nearestGuidance()
            } else if distance >= RouteAnalysisContants.softOffRouteAlignmentMaximumDistance && distance < RouteAnalysisContants.rerouteDistance {
                currentState = .offRoute(.hard, locationClient.currentLocation, locationClient.currentLocation.navigationRegion)
                guidance = .getBack
            } else {
                currentState = .offRoute(.shouldReroute, locationClient.currentLocation, locationClient.currentLocation.navigationRegion)
                guidance = .rerouting
            }
            routeAnalysisHandler(currentState, guidance)
        case .navigatingToEndPoint:
            break
        }
    }

    private func checkReachingStart() -> Bool {
        let currentLocation = locationClient.currentLocation
        let filtered = route.routes.map { $0.segments }.flatMap { $0 }.filter {
            return $0.start.distanceTo(currentLocation) < RouteAnalysisContants.startingReachRadius
        }
        return !filtered.isEmpty
    }

    private func checkReachingEnd() -> Bool {
        let currentLocation = locationClient.currentLocation
        return route.endLocation.location.distanceTo(currentLocation) < RouteAnalysisContants.endingReachRadius
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
        guard let nearestRoute = sortedRoutes.first else { return route.startLocation.location }
        currentRoute = nearestRoute
        var segments = nearestRoute.segments
        if let currentRouteIndex = route.routes.index(of: nearestRoute), currentRouteIndex != 0 {
            let previousRoute = route.routes[currentRouteIndex - 1]
            segments.append(contentsOf: previousRoute.segments)
            if currentRouteIndex != route.routes.count - 1 {
                let nextRoute = route.routes[currentRouteIndex + 1]
                segments.append(contentsOf: nextRoute.segments)
            }
        }
        let sortedSegments = segments.sorted { segment1, segment2 in
            let firstLocationToStart = segment1.start.distanceTo(currentLocation)
            let firstLocationToEnd = segment1.end.distanceTo(currentLocation)
            let secondLocationToStart = segment2.start.distanceTo(currentLocation)
            let secondLocationToEnd = segment2.end.distanceTo(currentLocation)
            let firstSegmentWeight = firstLocationToStart + firstLocationToEnd
            let secondSegmentWeight = secondLocationToStart + secondLocationToEnd
            return firstSegmentWeight < secondSegmentWeight
        }
        guard let nearestSegment = sortedSegments.first else { return nearestRoute.startPoint }
        currentSegment = nearestSegment
        let latitudeDiff = nearestSegment.start.latitude - nearestSegment.end.latitude
        let longitudeDiff = nearestSegment.start.longitude - nearestSegment.end.longitude
        guard longitudeDiff != 0, latitudeDiff != 0 else { return nearestSegment.start }
        let latitudeChunk = latitudeDiff / 20;
        let longitudeChunk = longitudeDiff / 20;
        var distances = [(CLLocationCoordinate2D, Double)]()
        for index in 0..<20 {
            let chunkedLatitude = nearestSegment.start.latitude + (latitudeChunk * Double(index))
            let chunkedLongitude = nearestSegment.start.longitude + (longitudeChunk * Double(index))
            let chunkedLocation = CLLocationCoordinate2D(latitude: chunkedLatitude, longitude: chunkedLongitude)
            let distance = chunkedLocation.distanceTo(currentLocation)
            distances.append((chunkedLocation, distance))
        }
        let sortedDistances = distances.sorted { locationData1, locationData2 -> Bool in
            return locationData1.1 < locationData2.1
        }
        guard let firstAligned = sortedDistances.first else { return nearestSegment.start }
        return firstAligned.0
    }

    private func nearestGuidance() -> NavigationGuidance {
        let nextSegments = nextSegmentsSet()
        guard let currentSegment = currentSegment, !nextSegments.isEmpty else { return .continueStraight }
        guard !nextSegments.isEmpty else {
            return .continueStraight
        }
        guard nextSegments.count >= 10 else {
            return .reachingEnd(nextSegments.count * 20)
        }
        var distance = currentSegment.length
        for segment in nextSegments {
            guard segment.length > 1 else {
                break
            }
            distance = distance + segment.length;
            let headingDiff = currentSegment.heading - segment.heading
            // Avoiding heading diff above or below 120 to overcome the bug with some reversed segments.
            if headingDiff < -RouteAnalysisContants.turnHeadingDifference && headingDiff < 180 - RouteAnalysisContants.turnHeadingDifference {
                return .turnRight(distance)
            } else if headingDiff > RouteAnalysisContants.turnHeadingDifference && headingDiff > -180 + RouteAnalysisContants.turnHeadingDifference {
                return .turnLeft(distance)
            }
        }
        return .continueStraight
    }

    private func nextSegmentsSet() -> [Segment] {
        guard
            let currentRoute = currentRoute,
            let currentSegment = currentSegment,
            let currentRouteIndex = route.routes.index(of: currentRoute),
            let currentSegmentIndex = currentRoute.segments.index(of: currentSegment)
        else {
            return []
        }
        var segments = [Segment]()
        let currentRouteSegments = currentRoute.segments.suffix(from: currentSegmentIndex + 1)
        segments.append(contentsOf: currentRouteSegments)
        let leftOverRoutes = route.routes.suffix(from: currentRouteIndex + 1)
        for route in leftOverRoutes {
            segments.append(contentsOf: route.segments)
            if segments.count >= 10 {
                return segments
            }
        }
        return segments
    }
}
