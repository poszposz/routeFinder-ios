//
//  LocationClient.swift
//  BikeRouteFinder
//

import Foundation
import CoreLocation

internal final class LocationClient: NSObject {

    var currentLocation = CLLocationCoordinate2D.krakowLocation

    var currentHeading: CLHeading?

    var initialLocationUpdateHandler: (() -> ())? {
        didSet {
            guard currentLocation != CLLocationCoordinate2D.krakowLocation, let initialLocationUpdateHandler = initialLocationUpdateHandler else { return }
            initialLocationUpdateHandler()
            self.initialLocationUpdateHandler = nil
        }
    }

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()

    private var locationUpdateHandler: ((CLLocation) -> ())?

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
}

extension LocationClient: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let suitableLocation = locations.first(where: { $0.horizontalAccuracy > 0 && $0.horizontalAccuracy < 200 }) else { return }
        currentLocation = suitableLocation.coordinate
        guard let initialLocationUpdateHandler = initialLocationUpdateHandler else { return }
        initialLocationUpdateHandler()
        self.initialLocationUpdateHandler = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }
}
