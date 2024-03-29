//
//  NavigationManager.swift
//  BikeRouteFinder
//

import Foundation
import MapKit
import CoreLocation

internal final class NavigationManager {

    enum State {
        case initial(CLLocationCoordinate2D)
        case userLocationMarked(CLLocationCoordinate2D)
        case preNavigation(DetailedRoute)
        case navigation(DetailedRoute, CLLocationCoordinate2D)

        var region: MKCoordinateRegion? {
            switch self {
            case .initial(let coordinate):
                return MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
            case .userLocationMarked(let coordinate):
                return MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            case .preNavigation(let detailedRoute):
                return detailedRoute.routeRegion ?? MKCoordinateRegion(center: detailedRoute.startLocation.location, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            case .navigation:
                return nil
            }
        }
    }

    enum RouteDrawing {
        case clear
        case route([Route])
        case reach([Segment])
    }

    enum InterfaceState {
        case search, preNavigation, navigation
    }

    var startLocation = ""

    var endLocation = ""

    var state: State {
        didSet {
            if let region = state.region {
                regionChangeHandler(region)
            }
            switch state {
            case .initial:
                allowsLocationChange = true
                routeDrawHandler(.clear)
                interfaceChangeHandler(.search)
            case .userLocationMarked:
                allowsLocationChange = true
                routeDrawHandler(.clear)
                interfaceChangeHandler(.search)
            case .preNavigation(let route):
                allowsLocationChange = true
                routeDrawHandler(.route(route.routes))
                routeDrawHandler(.reach([route.reachStartSegment, route.reachEndSegment]))
                interfaceChangeHandler(.preNavigation)
            case .navigation:
                allowsLocationChange = false
                interfaceChangeHandler(.navigation)
            }
        }
    }

    let locationClient = LocationClient()

    private lazy var networkClient = DefaultNetworkClient(requestBuilder: DefaultRequestBuilder(scheme: .http, host: "104.248.25.229", port: 3001))

    private lazy var geocoder = LocationDecoder()

    private var routeAnalyzer: RouteAnalyzer?

    private var isRerouting = false

    var allowsLocationChange = true

    let regionChangeHandler: (MKCoordinateRegion) -> ()

    let locationChangeHandler: (LocationType, Segment?) -> ()

    let headingChangeHandler: (CLLocationDirection) -> ()

    let routeDrawHandler: (RouteDrawing) -> ()

    let interfaceChangeHandler: (InterfaceState) -> ()

    let guidanceChangeHandler: (NavigationGuidance) -> ()

    let inputChangeHandler: (String, String) -> ()

    let errorHandler: (String) -> ()

    let loadingHandler: (Bool) -> ()

    init(
        regionChangeHandler: @escaping (MKCoordinateRegion) -> (),
        locationChangeHandler: @escaping (LocationType, Segment?) -> (),
        headingChangeHandler: @escaping (CLLocationDirection) -> (),
        routeDrawHandler: @escaping (RouteDrawing) -> (),
        interfaceChangeHandler: @escaping (InterfaceState) -> (),
        guidanceChangeHandler: @escaping (NavigationGuidance) -> (),
        inputChangeHandler: @escaping (String, String) -> (),
        errorHandler: @escaping (String) -> (),
        loadingHandler: @escaping (Bool) -> ()
    ) {
        state = .initial(CLLocationCoordinate2D.krakowLocation)
        self.regionChangeHandler = regionChangeHandler
        self.locationChangeHandler = locationChangeHandler
        self.headingChangeHandler = headingChangeHandler
        self.routeDrawHandler = routeDrawHandler
        self.interfaceChangeHandler = interfaceChangeHandler
        self.guidanceChangeHandler = guidanceChangeHandler
        self.inputChangeHandler = inputChangeHandler
        self.errorHandler = errorHandler
        self.loadingHandler = loadingHandler
    }

    func start() {
        locationClient.requestLocationPermission()
        locationClient.startUpdatingLocation()
        locationClient.initialLocationUpdateHandler = { [weak self] in
            guard let self = self else { return }
            self.state = .userLocationMarked(self.locationClient.currentLocation)
        }
    }

    func nextStep() {
        switch state {
        case .initial:
            break
        case .userLocationMarked:
            downloadRoute()
        case .preNavigation(let route):
            state = .navigation(route, locationClient.currentLocation)
            startNavigation(route: route)
        case .navigation(let route, _):
            state = .preNavigation(route)
            terminateNavigation()
        }
    }

    func previousStep() {
        switch state {
        case .initial:
            break
        case .userLocationMarked:
            break
        case .preNavigation:
            state = .userLocationMarked(locationClient.currentLocation)
            terminateNavigation()
        case .navigation(let route, _):
            state = .preNavigation(route)
        }
    }

    private func terminateNavigation() {
        routeAnalyzer?.stop()
        routeAnalyzer = nil
    }

    func markCurrentLocation() {
        loadingHandler(true)
        geocoder.reverseGeocodeLocation(locationClient.currentLocation, { [weak self] (address, error) in
            self?.loadingHandler(false)
            guard let self = self else { return }
            guard error == nil, let address = address else {
                self.errorHandler("Unable to decode user location into address.")
                return
            }
            self.startLocation = address
            self.inputChangeHandler(address, self.endLocation)
        })
    }

    func downloadRoute(location: CLLocationCoordinate2D? = nil, rerouting: Bool = false) {
        guard !startLocation.isEmpty && !endLocation.isEmpty else {
            errorHandler("You have to input start and end location in order to search for routes.")
            return
        }
        loadingHandler(true)
        let request = RouteDownloadRequest(start: startLocation, end: endLocation, startCoordinate: location)
        networkClient.perform(request: request) { [weak self] result in
            self?.loadingHandler(false)
            switch result {
            case .success(let detailedRoute):
                if rerouting {
                    self?.routeDrawHandler(.clear)
                    self?.terminateNavigation()
                    self?.routeDrawHandler(.route(detailedRoute.routes))
                    self?.startNavigation(route: detailedRoute)
                    self?.isRerouting = false
                } else {
                    self?.state = .preNavigation(detailedRoute)
                }
            case .error(let error):
                print("Error: \(error)")
                self?.errorHandler("No suitable route found from start to end location.")
            }
        }
    }

    func startNavigation(route: DetailedRoute) {
        routeAnalyzer = RouteAnalyzer(locationClient: locationClient, route: route) { [weak self] (state, guidance) in
            guard let self = self else { return }
            self.guidanceChangeHandler(guidance)
            switch state {
            case .navigatingToStartPoint:
                self.locationChangeHandler(.standard, self.routeAnalyzer?.currentSegment)
                self.regionChangeHandler(route.reachStartRegion)
            case .navigatingToEndPoint:
                self.regionChangeHandler(route.reachEndRegion)
            case let .navigating(location, region):
                self.locationChangeHandler(.aligned(location), self.routeAnalyzer?.currentSegment)
                self.regionChangeHandler(region)
            case let .offRoute(style, location, region):
                self.locationChangeHandler(.aligned(location), self.routeAnalyzer?.currentSegment)
                self.regionChangeHandler(region)
                if style == .hard {
                    self.guidanceChangeHandler(.getBack)
                } else if style == .shouldReroute {
                    self.guidanceChangeHandler(.rerouting)
                    if !self.isRerouting {
                        self.downloadRoute(location: self.locationClient.currentLocation, rerouting: true)
                        self.isRerouting = true
                    }
                }
            }
        }
        routeAnalyzer?.start()
    }
}
