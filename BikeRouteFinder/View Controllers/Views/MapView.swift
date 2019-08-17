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
            mapView.setRegion(region, animated: true)
        }
    }

    var showsUserLocation: Bool = true {
        didSet {
            mapView.showsUserLocation = showsUserLocation
        }
    }

    var alignedLocation: CLLocationCoordinate2D? {
        didSet {
            guard let alignedLocation = alignedLocation else { return }
            let contains = mapView.annotations.contains(where: { $0 === cyclistAnnotation })
            if !contains {
                mapView.addAnnotation(cyclistAnnotation)
            }
            UIView.animate(withDuration: 0.5, animations: {
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

    private var drawnRoutes = [Route]()

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
        drawnRoutes.removeAll()
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }

    private func draw(routes: [Route]) {
        routes.enumerated().forEach {
            draw(route: $1)
        }
        routes.filter { $0.category != "link" }.forEach { [weak self] route in
            let start = MKPointAnnotation()
            start.coordinate = route.startPoint
            start.title = "Start"

            let end = MKPointAnnotation()
            end.coordinate = route.endPoint
            end.title = "End"

            self?.mapView.addAnnotations([start, end])
        }
    }

    private func draw(route: Route) {
        guard !drawnRoutes.contains(route) else { return }
        drawnRoutes.append(route)
        draw(segments: route.segments, color: .blue)
    }

    private func draw(segments: [Segment], color: UIColor) {
        let coordinateGroups = segments.map { [$0.start, $0.end] }
        coordinateGroups.forEach {
            let route = RoutePolyline(coordinates: $0, count: 2)
            route.color = color
            mapView.add(route)
        }
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
        }
        if let overlay = overlay as? ReachPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = overlay.color
            renderer.strokeColor = overlay.color
            renderer.lineDashPattern = [NSNumber(integerLiteral: 5), NSNumber(integerLiteral: 5)]
            renderer.lineWidth = 2
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
