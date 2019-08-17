//
//  MapView.swift
//  BikeRouteFinder
//

import UIKit
import MapKit

internal final class MapView: UIView {

    var routes: [Route]? {
        didSet {
            clear()
            guard let routes = routes else { return }
            draw(routes: routes)
        }
    }

    var reachSegments: [Segment]? {
        didSet {
            guard let reachSegments = reachSegments else { return }
            drawReach(segments: reachSegments, color: .blue)
        }
    }

    var region: MKCoordinateRegion? {
        didSet {
            guard let region = region else { return }
            mapView.animatedZoom(zoomRegion: region, duration: 1.0)
        }
    }

    var debugSegmentOverlay: DebugPolyline?

    var debugSegment: Segment? {
        didSet {
            if let debugSegmentOverlay = debugSegmentOverlay {
                mapView.remove(debugSegmentOverlay)
            }
            guard let debugSegment = debugSegment else {
                return
            }
            let debugOverlay = DebugPolyline(coordinates: [debugSegment.start, debugSegment.end], count: 2)
            debugOverlay.color = .green
            mapView.add(debugOverlay)
            debugSegmentOverlay = debugOverlay
        }
    }

    var showsUserLocation: Bool = true {
        didSet {
//            mapView.showsUserLocation = showsUserLocation
        }
    }

    var alignedLocation: CLLocationCoordinate2D? {
        didSet {
            guard let alignedLocation = alignedLocation else { return }
            let contains = mapView.annotations.contains(where: { $0 === cyclistAnnotation })
            if !contains {
                mapView.addAnnotation(cyclistAnnotation)
            }
            UIView.animate(withDuration: 1.0, animations: {
                self.cyclistAnnotation.coordinate = alignedLocation
            }) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    guard let heading = self.heading else { return }
                    self.cyclistAnnotation.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(heading.trueHeading) * CGFloat.pi / 180)
                })
            }
        }
    }

    var heading: CLHeading?

    var cyclistAnnotation = CyclistAnnotation()

    var vertexTapHandler: ((Vertex) -> ())?

    private var vertices: [Vertex]?

    private var isUserLocationSet = false

    private var isFollowingUser = false

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView.autolayoutView()
        mapView.showsBuildings = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        return mapView
    }()

    init() {
        super.init(frame: .zero)
        loadLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadLayout() {
        addSubview(mapView)
        let constraints = [mapView.topAnchor.constraint(equalTo: topAnchor),
                           mapView.bottomAnchor.constraint(equalTo: bottomAnchor),
                           mapView.rightAnchor.constraint(equalTo: rightAnchor),
                           mapView.leftAnchor.constraint(equalTo: leftAnchor)]
        NSLayoutConstraint.activate(constraints)
    }

    func clear() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }

    private func draw(routes: [Route]) {
        routes.enumerated().forEach {
            draw(route: $1)
        }
    }

    private func draw(route: Route) {
        draw(segments: route.segments, color: route.category == "link" ? .red : .blue)
    }

    private func draw(segments: [Segment], color: UIColor) {
        let coordinates = segments.map { [$0.start, $0.end] }.flatMap { $0 }
        let route = RoutePolyline(coordinates: coordinates, count: coordinates.count)
        route.color = color
        mapView.add(route)

        // Uncomment to distinguish segments on map
//        let coordinateGroups = segments.map { [$0.start, $0.end] }
//        coordinateGroups.forEach {
//            let route = RoutePolyline(coordinates: $0, count: 2)
//            route.color = color
//            mapView.add(route)
//        }
    }

    private func drawReach(segments: [Segment], color: UIColor) {
        let coordinateGroups = segments.map { [$0.start, $0.end] }
        coordinateGroups.forEach {
            let route = ReachPolyline(coordinates: $0, count: 2)
            route.color = color
            mapView.add(route)
        }
    }
}

extension MapView: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? RoutePolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = overlay.color
            renderer.strokeColor = overlay.color
            renderer.lineWidth = 2
            return renderer

//            let gradientColors = [UIColor.green, UIColor.red]
//            let polylineRenderer = GradientPathRenderer(polyline: overlay, colors: gradientColors)
//            polylineRenderer.lineWidth = 7
//            return polylineRenderer
        }
        if let overlay = overlay as? ReachPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = overlay.color
            renderer.strokeColor = overlay.color
            renderer.lineDashPattern = [NSNumber(integerLiteral: 5), NSNumber(integerLiteral: 5)]
            renderer.lineWidth = 2
            return renderer
        }
        if let overlay = overlay as? DebugPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = overlay.color
            renderer.strokeColor = overlay.color
            renderer.lineWidth = 3
            return renderer
        }
        return MKPolylineRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CyclistAnnotation else { return nil }
        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "CyclistAnnotation")
        view.frame = CGRect(x: 0, y: 0, width: 28, height: 48)
        let mainView = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 48))
        mainView.layer.masksToBounds = false
        let imageView = UIImageView(image: annotation.image)
        imageView.frame = CGRect(x: 0, y: 0, width: 28, height: 48)
        mainView.addSubview(imageView)
        view.addSubview(mainView)
        annotation.imageView = imageView
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let location = view.annotation?.coordinate, let vertices = vertices else { return }
        let first = vertices.first(where: { return $0.centerLocation.latitude == location.latitude && $0.centerLocation.longitude == location.longitude })
        guard let firstVertex = first else { return }
        vertexTapHandler?(firstVertex)
    }
}
