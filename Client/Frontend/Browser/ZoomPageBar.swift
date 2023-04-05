// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

protocol ZoomPageBarDelegate: AnyObject {
    func zoomPageDidPressClose()
}

class ZoomPageBar: UIView {
    private struct UX {
        static let leadingTrailingPadding: CGFloat = 20
        static let topBottomPadding: CGFloat = 18
        static let stepperWidth: CGFloat = 222
        static let stepperHeight: CGFloat = 36
        static let stepperTopBottomPadding: CGFloat = 10
        static let stepperCornerRadius: CGFloat = 8
        static let stepperMinTrailing: CGFloat = 10
        static let stepperShadowRadius: CGFloat = 4
        static let stepperSpacing: CGFloat = 12
        static let stepperShadowOpacity: Float = 1
        static let stepperShadowOffset = CGSize(width: 0, height: 4)
        static let separatorWidth: CGFloat = 1
        static let separatorHeightMultiplier = 0.74
        static let fontSize: CGFloat = 16
        static let lowerZoomLimit: CGFloat = 0.5
        static let upperZoomLimit: CGFloat = 2.0
        static let zoomInButtonInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 12)
        static let zoomOutButtonInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 0)
        static let startCGColor = UIColor(red: 58/255, green: 57/255, blue: 68/255, alpha: 0.0).cgColor
        static let endCGColor = UIColor(red: 58/255, green: 57/255, blue: 68/255, alpha: 0.7).cgColor
    }

    weak var delegate: ZoomPageBarDelegate?
    private let gestureRecognizer = UITapGestureRecognizer()
    private var stepperCompactConstraints = [NSLayoutConstraint]()
    private var stepperDefaultConstraints = [NSLayoutConstraint]()
    private var gradientViewHeightConstraint = NSLayoutConstraint()

    private let tab: Tab

    private let leftSeparator: UIView = .build()
    private let rightSeparator: UIView = .build()
    private let gradientView: UIView = .build()
    private let gradient = CAGradientLayer()

    private let stepperContainer: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = UX.stepperSpacing
        view.layer.cornerRadius = UX.stepperCornerRadius
        view.layer.shadowRadius = UX.stepperShadowRadius
        view.layer.shadowOffset = UX.stepperShadowOffset
        view.layer.shadowOpacity = UX.stepperShadowOpacity
        view.clipsToBounds = false
    }

    private let zoomOutButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.subtract), for: [])
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setInsets(forContentPadding: UX.zoomOutButtonInsets, imageTitlePadding: 0)
    }

    private let zoomInButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.add), for: [])
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setInsets(forContentPadding: UX.zoomInButtonInsets, imageTitlePadding: 0)
    }

    private let zoomLevel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .callout,
                                                                   size: UX.fontSize,
                                                                   weight: .semibold)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
    }

    private let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.xMark), for: [])
        button.accessibilityLabel = .FindInPageDoneAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.FindInPage.findInPageCloseButton
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    init(tab: Tab) {
        self.tab = tab

        super.init(frame: .zero)
        self.tab.urlHostDelegate = self

        setupViews()
        setupLayout()
        setupGradientViewLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupGradient()
        remakeGradientViewHeightConstraint()
        updateStepperConstraintsBasedOnSizeClass()
    }

    private func setupViews() {
        zoomInButton.addTarget(self, action: #selector(didPressZoomIn), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(didPressZoomOut), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)

        gestureRecognizer.addTarget(self, action: #selector(didPressReset))
        zoomLevel.addGestureRecognizer(gestureRecognizer)

        updateZoomLabel()
        checkPageZoomLimits()

        [zoomOutButton, leftSeparator, zoomLevel, rightSeparator, zoomInButton].forEach {
            stepperContainer.addArrangedSubview($0)
        }

        addSubviews(gradientView, stepperContainer, closeButton)
    }

    private func setupLayout() {
        stepperCompactConstraints.append(stepperContainer.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                   constant: UX.leadingTrailingPadding))
        stepperDefaultConstraints.append(stepperContainer.centerXAnchor.constraint(equalTo: centerXAnchor))
        stepperDefaultConstraints.append(stepperContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                                                                   constant: UX.leadingTrailingPadding))
        setupSeparator(leftSeparator)
        setupSeparator(rightSeparator)

        NSLayoutConstraint.activate([
            stepperContainer.topAnchor.constraint(equalTo: topAnchor,
                                                  constant: UX.stepperTopBottomPadding),
            stepperContainer.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                     constant: -UX.stepperTopBottomPadding),
            stepperContainer.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                       constant: -UX.stepperMinTrailing),
            stepperContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.stepperHeight),
            stepperContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.stepperWidth),
            stepperContainer.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: -UX.leadingTrailingPadding),
        ])
    }

    private func setupSeparator(_ separator: UIView) {
        separator.widthAnchor.constraint(equalToConstant: UX.separatorWidth).isActive = true
        separator.heightAnchor.constraint(equalTo: stepperContainer.heightAnchor,
                                          multiplier: UX.separatorHeightMultiplier).isActive = true
    }

    private func setupGradient() {
        gradient.frame = gradientView.bounds
        gradient.colors = traitCollection.userInterfaceIdiom == .pad ?
            [UX.endCGColor, UX.startCGColor] :
            [UX.startCGColor, UX.endCGColor]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradientView.layer.addSublayer(gradient)
    }

    private func setupGradientViewLayout() {
        gradientView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        if traitCollection.userInterfaceIdiom == .pad {
            gradientView.topAnchor.constraint(equalTo: bottomAnchor).isActive = true
        } else {
            gradientView.bottomAnchor.constraint(equalTo: topAnchor).isActive = true
        }
    }

    private func remakeGradientViewHeightConstraint() {
        let viewPortHeight: CGFloat = (UIScreen.main.bounds.height -
                                       UIConstants.TopToolbarHeightMax -
                                       UIConstants.ZoomPageBarHeight) * 0.2
        gradientViewHeightConstraint.isActive = false
        gradientViewHeightConstraint = gradientView.heightAnchor.constraint(equalToConstant: viewPortHeight)
        gradientViewHeightConstraint.isActive = true
    }

    private func updateZoomLabel() {
        zoomLevel.text = NumberFormatter.localizedString(from: NSNumber(value: tab.pageZoom), number: .percent)
        zoomLevel.isEnabled = tab.pageZoom == 1.0 ? false : true
        gestureRecognizer.isEnabled = !(tab.pageZoom == 1.0)
    }

    private func enableZoomButtons() {
        zoomInButton.isEnabled = true
        zoomOutButton.isEnabled = true
    }

    private func checkPageZoomLimits() {
        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomOutButton.isEnabled = false
        } else if tab.pageZoom >= UX.upperZoomLimit {
            zoomInButton.isEnabled = false
        } else { enableZoomButtons() }
    }

    private func updateStepperConstraintsBasedOnSizeClass() {
        if traitCollection.horizontalSizeClass == .regular || UIWindow.isLandscape {
            stepperDefaultConstraints.forEach { $0.isActive = true }
            stepperCompactConstraints.forEach { $0.isActive = false }
        } else {
            stepperDefaultConstraints.forEach { $0.isActive = false }
            stepperCompactConstraints.forEach { $0.isActive = true }
        }
    }

    @objc
    private func didPressZoomIn(_ sender: UIButton) {
        tab.zoomIn()
        updateZoomLabel()

        zoomOutButton.isEnabled = true
        if tab.pageZoom >= UX.upperZoomLimit {
            zoomInButton.isEnabled = false
        }
    }

    @objc
    private func didPressZoomOut(_ sender: UIButton) {
        tab.zoomOut()
        updateZoomLabel()

        zoomInButton.isEnabled = true
        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomOutButton.isEnabled = false
        }
    }

    @objc
    private func didPressReset(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            tab.resetZoom()
            updateZoomLabel()
            enableZoomButtons()
        }
    }

    @objc
    private func didPressClose(_ sender: UIButton) {
        delegate?.zoomPageDidPressClose()
    }
}

extension ZoomPageBar: URLHostDelegate {
    func hostDidSet() {
        updateZoomLabel()
        checkPageZoomLimits()
    }
}

extension ZoomPageBar: ThemeApplicable {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        stepperContainer.backgroundColor = theme.colors.layer5
        stepperContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor

        leftSeparator.backgroundColor = theme.colors.borderPrimary
        rightSeparator.backgroundColor = theme.colors.borderPrimary

        zoomLevel.tintColor = theme.colors.textPrimary

        zoomInButton.tintColor = theme.colors.iconPrimary
        zoomOutButton.tintColor = theme.colors.iconPrimary
        closeButton.tintColor = theme.colors.iconPrimary
    }
}
