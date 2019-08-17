//
//  VertexDetailViewController.swift
//  BikeRouteFinder
//

import UIKit
import MapKit

internal final class VertexDetailViewController: UIViewController {

    private lazy var mapView = MapView.autolayoutView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView.autolayoutView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VertexDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.autolayoutView()
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(mapView)
        stackView.addArrangedSubview(tableView)
        stackView.axis = .vertical
        return stackView
    }()

    private var drawIncoming = false

    private var drawOutcoming = false

    private let vertex: Vertex

    private let allRoutes: [Route]

    init(vertex: Vertex) {
        self.vertex = vertex
        allRoutes = [vertex.incomingRoutes, vertex.outcomingRoutes].flatMap { $0 }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(stackView)
        let constraints = [stackView.topAnchor.constraint(equalTo: view.topAnchor),
                           stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                           stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
                           stackView.leftAnchor.constraint(equalTo: view.leftAnchor)]
        NSLayoutConstraint.activate(constraints)
        mapView.routes = allRoutes
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension VertexDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allRoutes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? VertexDetailTableViewCell else { fatalError() }
        let route = allRoutes[indexPath.row]
        cell.load(route: route)
        return cell
    }
}
