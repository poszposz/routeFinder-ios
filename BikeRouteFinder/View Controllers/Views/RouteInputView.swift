//
//  RouteInputView.swift
//  BikeRouteFinder
//

import Foundation
import UIKit

internal final class RouteInputView: UIControl {

    enum Action {
        case markCurrentLocation, search
    }

    enum Change {
        case start(String)
        case end(String)
    }

    var startLocation: String = "" {
        didSet {
            startInputTextField.text = startLocation
        }
    }

    var endLocation: String = "" {
        didSet {
            endInputTextField.text = endLocation
        }
    }

    var isShrunken = false {
        didSet {
            endInputTextField.isHidden = isShrunken
            startInputTextField.isHidden = isShrunken
        }
    }

    override var isFirstResponder: Bool {
        return startInputTextField.isFirstResponder || endInputTextField.isFirstResponder
    }

    override var isEnabled: Bool {
        didSet {
            startInputTextField.isEnabled = isEnabled
            endInputTextField.isEnabled = isEnabled
        }
    }

    private lazy var inputsContainer: UIStackView = {
        let stackView = UIStackView.autolayoutView()
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.axis = .vertical
        stackView.addArrangedSubview(startInputTextField)
        stackView.addArrangedSubview(endInputTextField)
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var markCurrentLocationButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mark_location_icon"), for: .normal)
        button.addTarget(self, action: #selector(markCurrentLocation), for: .touchUpInside)
        return button
    }()

    private lazy var startInputTextField: UITextField = {
        let textField = PaddingTextField.autolayoutView()
        textField.rightViewMode = .always
        textField.autocorrectionType = .no
        textField.placeholder = "Enter start location"
        textField.layer.cornerRadius = 6
        textField.layer.masksToBounds = true
        textField.backgroundColor = .white
        textField.delegate = self
        textField.returnKeyType = .next
        textField.addTarget(self, action: #selector(startPhraseDidChange(sender:)), for: .editingChanged)
        return textField
    }()

    private lazy var endInputTextField: UITextField = {
        let textField = PaddingTextField.autolayoutView()
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Enter end location"
        textField.layer.cornerRadius = 6
        textField.layer.masksToBounds = true
        textField.backgroundColor = .white
        textField.delegate = self
        textField.returnKeyType = .search
        textField.addTarget(self, action: #selector(endPhraseDidChange(sender:)), for: .editingChanged)
        return textField
    }()

    let actionHandler: (Action) -> ()

    let changeHandler: (Change) -> ()

    init(actionHandler: @escaping (Action) -> (), changeHandler: @escaping (Change) -> ()) {
        self.actionHandler = actionHandler
        self.changeHandler = changeHandler
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true
        loadLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadLayout() {
        addSubview(inputsContainer)
        addSubview(markCurrentLocationButton)
        let constraints = [
            inputsContainer.topAnchor.constraint(equalTo: topAnchor),
            inputsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            inputsContainer.rightAnchor.constraint(equalTo: rightAnchor),
            inputsContainer.leftAnchor.constraint(equalTo: leftAnchor),
            inputsContainer.widthAnchor.constraint(equalTo: widthAnchor),
            startInputTextField.heightAnchor.constraint(equalToConstant: 40),
            endInputTextField.heightAnchor.constraint(equalToConstant: 40),
            startInputTextField.widthAnchor.constraint(equalTo: inputsContainer.widthAnchor),
            endInputTextField.widthAnchor.constraint(equalTo: inputsContainer.widthAnchor),
            markCurrentLocationButton.widthAnchor.constraint(equalToConstant: 40),
            markCurrentLocationButton.heightAnchor.constraint(equalToConstant: 40),
            markCurrentLocationButton.rightAnchor.constraint(equalTo: startInputTextField.rightAnchor),
            markCurrentLocationButton.centerYAnchor.constraint(equalTo: startInputTextField.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func markCurrentLocation() {
        actionHandler(.markCurrentLocation)
    }

    @objc private func startPhraseDidChange(sender: UITextField) {
        startLocation = sender.text.emptyIfNil
        changeHandler(.start(startLocation))
    }

    @objc private func endPhraseDidChange(sender: UITextField) {
        endLocation = sender.text.emptyIfNil
        changeHandler(.end(endLocation))
    }

    override var intrinsicContentSize: CGSize {
        return inputsContainer.intrinsicContentSize
    }
}

extension RouteInputView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == startInputTextField {
            endInputTextField.becomeFirstResponder()
            return true
        }
        actionHandler(.search)
        endInputTextField.resignFirstResponder()
        return true
    }
}
