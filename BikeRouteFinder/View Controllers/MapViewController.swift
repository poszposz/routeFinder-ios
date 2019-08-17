//
//  MapViewController.swift
//  BikeRouteFinder
//
//  Created by Jan Posz on 30.06.2018.
//  Copyright © 2018 agh. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {

    private lazy var mapView = MapView.autolayoutView()

    private lazy var routeInputView = RouteInputView(actionHandler: routeInputActionHandler, changeHandler: routeInputChangeHandler)

    private lazy var navigationBannerView = NavigationBannerView.autolayoutView()

    private lazy var routeInputActionHandler: (RouteInputView.Action) -> () = { [weak self] action in
        guard let self = self else { return }
        switch action {
        case .markCurrentLocation:
            self.navigationManager.markCurrentLocation()
        case .search:
            self.navigationManager.downloadRoute()
        }
    }

    private lazy var routeInputChangeHandler: (RouteInputView.Change) -> () = { [weak self] change in
        guard let self = self else { return }
        switch change {
        case .start(let start):
            self.navigationManager.startLocation = start
        case .end(let end):
            self.navigationManager.endLocation = end
        }
    }

    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Search", for: .normal)
        button.setImage(UIImage(named: "navigate_icon"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        button.semanticContentAttribute = .forceRightToLeft
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(nextStep), for: .touchUpInside)
        return button
    }()

    private lazy var backButton = UIBarButtonItem(image: UIImage(named: "back_button"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(back))

    private var loadingIndicator: UIBarButtonItem {
        let loader = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loader.startAnimating()
        return UIBarButtonItem(customView: loader)
    }

    private var searchButtonBottomAnchor: NSLayoutConstraint?

    private var navigationBannerViewHeight: NSLayoutConstraint?

    private var isMenuShown = true

    private var isBannerShown = false

    private lazy var navigationManager = NavigationManager(regionChangeHandler: regionChangeHandler,
                                                           locationChangeHandler: locationChangeHandler,
                                                           headingChangeHandler: headingChangeHandler,
                                                           routeDrawHandler: routeDrawHandler,
                                                           interfaceChangeHandler: interfaceChangeHandler,
                                                           guidanceChangeHandler: guidanceChangeHandler,
                                                           inputChangeHandler: inputChangeHandler,
                                                           errorHandler: errorHandler,
                                                           loadingHandler: loadingHandler)

    private lazy var regionChangeHandler: (MKCoordinateRegion) -> () = { [weak self] region in
        guard let self = self else { return }
        self.mapView.region = region
    }

    private lazy var locationChangeHandler: (LocationType, Segment?) -> () = { [weak self] location, segment in
        guard let self = self else { return }
        self.mapView.debugSegment = segment
        switch location {
        case .aligned(let location):
            self.mapView.showsUserLocation = false
            self.mapView.alignedLocation = location
            self.mapView.heading = self.navigationManager.locationClient.currentHeading
        case .standard:
            self.mapView.showsUserLocation = true
        }
    }

    private lazy var headingChangeHandler: (CLLocationDirection) -> () = { [weak self] heading in
        guard let self = self else { return }
    }

    private lazy var routeDrawHandler: (NavigationManager.RouteDrawing) -> () = { [weak self] route in
        guard let self = self else { return }
        switch route {
        case .clear:
            self.mapView.clear()
        case .route(let routes):
            self.mapView.routes = routes
        case .reach(let reach):
            self.mapView.reachSegments = reach
        }
    }

    private lazy var interfaceChangeHandler: (NavigationManager.InterfaceState) -> () = { [weak self] state in
        guard let self = self else { return }
        switch state {
        case .search:
            self.routeInputView.isEnabled = true
            self.navigationItem.leftBarButtonItem = nil
            self.mapView.clear()
            self.routeInputView.startLocation = ""
            self.routeInputView.endLocation = ""
            self.searchButton.setTitle("Search", for: .normal)
            self.searchButton.setTitleColor(.black, for: .normal)
            self.searchButton.tintColor = .black
            self.searchButton.backgroundColor = .white
        case .preNavigation:
            if self.isBannerShown {
                self.setNavigationBannerHidden(true) {
                    self.setMenuHidden(false, hideActionElements: false)
                }
            } else {
                self.setMenuHidden(false, hideActionElements: false)
            }
            self.routeInputView.isEnabled = true
            self.navigationItem.leftBarButtonItem = self.backButton
            self.searchButton.setTitle("Navigate", for: .normal)
            self.setMenuHidden(false)
            self.searchButton.setTitleColor(.black, for: .normal)
            self.searchButton.tintColor = .black
            self.searchButton.backgroundColor = .white
        case .navigation:
            self.setMenuHidden(true, hideActionElements: false) {
                self.setNavigationBannerHidden(false)
            }
            self.routeInputView.isEnabled = false
            self.navigationItem.leftBarButtonItem = self.backButton
            self.searchButton.setTitle("Stop navigation", for: .normal)
            self.searchButton.setTitleColor(.white, for: .normal)
            self.searchButton.tintColor = .white
            self.searchButton.backgroundColor = .blue
        }
    }

    private lazy var guidanceChangeHandler: (NavigationGuidance) -> () = { [weak self] guidance in
        self?.navigationBannerView.loadGuidance(guidance)
    }

    private lazy var inputChangeHandler: (String, String) -> () = { [weak self] start, end in
        guard let self = self else { return }
        self.routeInputView.startLocation = start
        self.routeInputView.endLocation = end
    }

    private lazy var errorHandler: (String) -> () = { [weak self] message in
        guard let self = self else { return }
        self.presentAlert(message: message)
    }

    private lazy var loadingHandler: (Bool) -> () = { [weak self] isLoading in
        guard let self = self else { return }
        self.searchButton.isEnabled = !isLoading
        self.routeInputView.isEnabled = !isLoading
        self.backButton.isEnabled = !isLoading
        if isLoading {
            self.navigationItem.rightBarButtonItem = self.loadingIndicator
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationManager.start()
        navigationItem.titleView = UIImageView(image: UIImage(named: "bike_icon"))
        navigationController?.navigationBar.tintColor = .black
        view.addSubview(mapView)
        view.addSubview(routeInputView)
        view.addSubview(searchButton)
        view.addSubview(navigationBannerView)
        let searchButtonBottomAnchor = searchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        let navigationBannerViewHeight = navigationBannerView.heightAnchor.constraint(equalToConstant: 0)
        let constraints = [
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
            searchButtonBottomAnchor,
            searchButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            searchButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 60),
            routeInputView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 15),
            routeInputView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            routeInputView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            navigationBannerView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            navigationBannerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            navigationBannerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            navigationBannerViewHeight
        ]
        NSLayoutConstraint.activate(constraints)
        self.navigationBannerViewHeight = navigationBannerViewHeight
        self.searchButtonBottomAnchor = searchButtonBottomAnchor
        handleVertexTap()
    }

    private func handleVertexTap() {
        mapView.vertexTapHandler = { [weak self] vertex in
            let viewController = VertexDetailViewController(vertex: vertex)
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    @objc private func nextStep() {
        navigationManager.nextStep()
    }

    @objc private func back() {
        navigationManager.previousStep()
    }

    private func setMenuHidden(_ hidden: Bool, hideActionElements: Bool = true, completion: (() -> ())? = nil) {
        if hideActionElements {
            searchButtonBottomAnchor?.constant = hidden ? 60 : -60
            navigationController?.setNavigationBarHidden(hidden, animated: true)
        }
        isMenuShown = !hidden
        UIView.animate(withDuration: 0.2, animations: {
            self.routeInputView.isShrunken = hidden
            self.view.layoutIfNeeded()
        }) { _ in
            completion?()
        }
    }

    private func setNavigationBannerHidden(_ hidden: Bool, completion: (() -> ())? = nil) {
        navigationBannerViewHeight?.constant = hidden ? 0 : 100
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.isBannerShown.toggle()
        }) { _ in
            completion?()
        }
    }

    private func presentAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
