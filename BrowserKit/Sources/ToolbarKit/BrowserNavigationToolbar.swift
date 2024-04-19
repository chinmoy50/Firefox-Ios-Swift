// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Navigation toolbar implementation.
public class BrowserNavigationToolbar: UIView, NavigationToolbar, ThemeApplicable {
    private enum UX {
        static let horizontalEdgeSpace: CGFloat = 16
        static let buttonSize = CGSize(width: 48, height: 48)
    }

    private lazy var actionStack: UIStackView = .build { view in
        view.distribution = .equalSpacing
    }
    private var theme: Theme?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(state: NavigationToolbarState) {
        updateActionStack(toolbarElements: state.actions)
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(actionStack)

        NSLayoutConstraint.activate([
            actionStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalEdgeSpace),
            actionStack.topAnchor.constraint(equalTo: topAnchor),
            actionStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalEdgeSpace),
        ])
    }

    private func updateActionStack(toolbarElements: [ToolbarElement]) {
        actionStack.removeAllArrangedViews()
        toolbarElements.forEach { toolbarElement in
            let button = ToolbarButton()
            button.configure(element: toolbarElement)
            actionStack.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
                button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
            ])

            if let theme {
                // As we recreate the buttons we need to apply the theme for them to be displayed correctly
                button.applyTheme(theme: theme)
            }
        }
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        self.theme = theme
    }
}
