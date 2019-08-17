//
//  VertexDetailTableViewCell.swift
//  BikeRouteFinder
//

import UIKit

internal final class VertexDetailTableViewCell: UITableViewCell {

    private lazy var routeNameLabel = UILabel.autolayoutView()

    private lazy var routeLengthLabel = UILabel.autolayoutView()

    private lazy var vertexDataLabel = UILabel.autolayoutView()

    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView.autolayoutView()
        stackView.addArrangedSubview(verticalStackView)
        stackView.addArrangedSubview(routeLengthLabel)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView.autolayoutView()
        stackView.addArrangedSubview(routeNameLabel)
        stackView.addArrangedSubview(vertexDataLabel)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadView() {
        routeNameLabel.font = UIFont.systemFont(ofSize: 14)
        routeLengthLabel.font = UIFont.systemFont(ofSize: 14)
        routeLengthLabel.textAlignment = .right
        vertexDataLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(horizontalStackView)
        let constraints = [
            horizontalStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            horizontalStackView.rightAnchor.constraint(equalTo: contentView.layoutMarginsGuide.rightAnchor),
            horizontalStackView.leftAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leftAnchor),
            horizontalStackView.heightAnchor.constraint(equalToConstant: 50)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func load(route: Route) {
        let routeName = route.name.emptyIfNil.isEmpty ? "unnamed" : route.name.emptyIfNil
        routeNameLabel.text = "\(routeName) \(route.segments.count) segments"
        routeLengthLabel.text = "\(route.length) meters"
        vertexDataLabel.text = "starts in: \(route.startPointVertexId), ends in: \(route.endPointVertexId)"
    }
}
