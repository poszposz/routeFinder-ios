//
//  MKMapView.swift
//  BikeRouteFinder
//

import Foundation

import MapKit

extension MKMapView {

    func animatedZoom(zoomRegion: MKCoordinateRegion, duration: TimeInterval) {
        MKMapView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.setRegion(zoomRegion, animated: true)
        }, completion: nil)
    }
}
