//
//  NavigationState.swift
//  BikeRouteFinder
//

import CoreLocation
import MapKit

enum NavigationState {
    case navigatingToStartPoint(MKCoordinateRegion)
    case navigatingToEndPoint(MKCoordinateRegion)
    case navigating(CLLocationCoordinate2D, MKCoordinateRegion)
    case offRoute(OffRouteStyle, CLLocationCoordinate2D, MKCoordinateRegion)
}

enum OffRouteStyle {
    case soft, hard, shouldReroute
}
