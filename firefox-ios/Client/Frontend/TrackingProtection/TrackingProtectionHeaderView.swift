// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import ComponentLibrary

class TrackingProtectionHeaderView: UIView {
    let siteTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
    }

    private var closeButton: CloseButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
    }

    var backButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle(.KeyboardShortcuts.Back, for: .normal)
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.font = TPMenuUX.Fonts.viewTitleLabels.scaledFont()
    }

    private let horizontalLine: UIView = .build { _ in }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Setup
    private func setupView() {
        addSubviews(siteTitleLabel, backButton, closeButton, horizontalLine)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: TPMenuUX.UX.TrackingDetails.imageMargins
            ),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            siteTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            siteTitleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            siteTitleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),
            siteTitleLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: TPMenuUX.UX.TrackingDetails.baseDistance
            ),
            siteTitleLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -TPMenuUX.UX.TrackingDetails.baseDistance
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height)
        ])
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .tinted(withColor: theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        backButton.tintColor = theme.colors.iconAction
        backButton.setTitleColor(theme.colors.textAccent, for: .normal)
        horizontalLine.backgroundColor = theme.colors.borderPrimary
        siteTitleLabel.textColor = theme.colors.textPrimary
    }
}
