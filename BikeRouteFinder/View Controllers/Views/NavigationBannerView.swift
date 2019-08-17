//
//  NavigationBannerView.swift
//  BikeRouteFinder
//

import UIKit

internal final class NavigationBannerView: UIView {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.autolayoutView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.addArrangedSubview(navigationImage)
        stackView.addArrangedSubview(guideLabel)
        return stackView
    }()

    private lazy var guideLabel: UILabel = {
        let label = UILabel.autolayoutView()
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()

    private lazy var separator: UIView = {
        let view = UIView.autolayoutView()
        view.backgroundColor = .lightGray
        view.alpha = 0.5
        return view
    }()

    private lazy var navigationImage = UIImageView.autolayoutView()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true
        loadLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadLayout() {
        backgroundColor = .white
        addSubview(stackView)
        addSubview(separator)
        let constraints = [
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.rightAnchor.constraint(equalTo: rightAnchor),
            separator.leftAnchor.constraint(equalTo: leftAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func loadGuidance(_ guidance: NavigationGuidance) {
        guideLabel.text = guidance.title
        navigationImage.image = guidance.icon
        navigationImage.isHidden = guidance.icon == nil
    }
}
