// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct CardContainerModel {
    public let view: UIView
    public let a11yId: String

    public init(view: UIView, a11yId: String) {
        self.view = view
        self.a11yId = a11yId
    }
}

public class CardContainer: UIView, ThemeApplicable {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    // MARK: - Properties

    // UI
    private lazy var rootView: UIView = .build { _ in }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        rootView.layer.shadowPath = UIBezierPath(roundedRect: rootView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
    }

    public func applyTheme(theme: Theme) {
        rootView.backgroundColor = theme.colors.layer2
        setupShadow(theme: theme)
        (rootView.subviews.first as? ThemeApplicable)?.applyTheme(theme: theme)
    }

    public func configure(_ viewModel: CardContainerModel) {
        rootView.subviews.forEach { $0.removeFromSuperview() }
        rootView.addSubview(viewModel.view)
        rootView.accessibilityIdentifier = viewModel.a11yId

        NSLayoutConstraint.activate([
            viewModel.view.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                    constant: UX.horizontalPadding),
            viewModel.view.topAnchor.constraint(equalTo: rootView.topAnchor,
                                                constant: UX.verticalPadding),
            viewModel.view.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                     constant: -UX.horizontalPadding),
            viewModel.view.bottomAnchor.constraint(equalTo: rootView.bottomAnchor,
                                                   constant: -UX.verticalPadding),
        ])
    }

    private func setupLayout() {
        addSubview(rootView)

        NSLayoutConstraint.activate([
            rootView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootView.topAnchor.constraint(equalTo: topAnchor),
            rootView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupShadow(theme: Theme) {
        rootView.layer.cornerRadius = UX.cornerRadius
        rootView.layer.shadowPath = UIBezierPath(roundedRect: rootView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
        rootView.layer.shadowRadius = UX.shadowRadius
        rootView.layer.shadowOffset = UX.shadowOffset
        rootView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootView.layer.shadowOpacity = UX.shadowOpacity
    }
}
