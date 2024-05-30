// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class LocationView: UIView, UITextFieldDelegate, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let searchEngineImageViewCornerRadius: CGFloat = 4
        static let lockIconWidth: CGFloat = 20
        static let searchEngineImageViewSize = CGSize(width: 24, height: 24)
        static let transitionDuration: TimeInterval = 0.3
    }

    private var urlAbsolutePath: String?
    private var notifyTextChanged: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }

    private var doesURLTextFieldExceedViewWidth: Bool {
        guard let text = urlTextField.text, let font = urlTextField.font else {
            return false
        }
        let locationViewWidth = frame.width - (UX.horizontalSpace * 2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let urlTextFieldWidth = text.size(withAttributes: fontAttributes).width
        return urlTextFieldWidth >= locationViewWidth
    }

    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private var clearButtonWidthConstraint: NSLayoutConstraint?
    private var iconContainerStackViewWidthConstraint: NSLayoutConstraint?
    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?

    private lazy var iconContainerStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
    }

    private lazy var searchEngineContentView: UIView = .build()

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.searchEngineImageViewCornerRadius
        imageView.isAccessibilityElement = true
    }

    private lazy var lockIconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var urlTextField: LocationTextField = .build { [self] urlTextField in
        urlTextField.backgroundColor = .clear
        urlTextField.font = FXFontStyles.Regular.body.scaledFont()
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.delegate = self
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()

        urlTextField.addTarget(self, action: #selector(LocationView.textDidChange), for: .editingChanged)
        notifyTextChanged = { [self] in
            guard urlTextField.isEditing else { return }

            urlTextField.text = urlTextField.text?.lowercased()
            urlAbsolutePath = urlTextField.text
            locationViewDelegate?.locationViewDidEnterText(urlTextField.text ?? "")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return urlTextField.resignFirstResponder()
    }

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        searchEngineImageView.image = state.searchEngineImage
        lockIconImageView.image = UIImage(named: state.lockIconImageName)?.withRenderingMode(.alwaysTemplate)
        configureURLTextField(state)
        configureA11y(state)
        formatAndTruncateURLTextField()
        locationViewDelegate = delegate
    }

    // MARK: - Layout
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async { [self] in
            formatAndTruncateURLTextField()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        addSubviews(urlTextField, iconContainerStackView, gradientView)
        searchEngineContentView.addSubview(searchEngineImageView)
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        NSLayoutConstraint.activate(
            [
                gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
                gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
                gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
                gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),

                urlTextField.topAnchor.constraint(equalTo: topAnchor),
                urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
                urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalSpace),

                searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.height),
                searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.width),
                searchEngineImageView.leadingAnchor.constraint(equalTo: searchEngineContentView.leadingAnchor),
                searchEngineImageView.trailingAnchor.constraint(equalTo: searchEngineContentView.trailingAnchor),
                searchEngineImageView.topAnchor.constraint(greaterThanOrEqualTo: searchEngineContentView.topAnchor),
                searchEngineImageView.bottomAnchor.constraint(lessThanOrEqualTo: searchEngineContentView.bottomAnchor),
                searchEngineImageView.centerXAnchor.constraint(equalTo: searchEngineContentView.centerXAnchor),
                searchEngineImageView.centerYAnchor.constraint(equalTo: searchEngineContentView.centerYAnchor),

                iconContainerStackView.topAnchor.constraint(equalTo: topAnchor),
                iconContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                iconContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
            ]
        )
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        let showGradientForLongURL = doesURLTextFieldExceedViewWidth && !urlTextField.isFirstResponder
        gradientView.isHidden = !showGradientForLongURL
        gradientLayer.frame = gradientView.bounds
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let isTextFieldFocused = urlTextField.isFirstResponder
        let shouldAdjustForOverflow = doesURLTextFieldExceedViewWidth && !isTextFieldFocused
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isTextFieldFocused

        if shouldAdjustForOverflow {
            updateURLTextFieldLeadingConstraint(equalTo: iconContainerStackView.leadingAnchor)
        } else if shouldAdjustForNonEmpty {
            updateURLTextFieldLeadingConstraint(equalTo: iconContainerStackView.trailingAnchor, constant: UX.horizontalSpace)
        }
    }

    private func updateURLTextFieldLeadingConstraint(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) {
        urlTextFieldLeadingConstraint?.isActive = false
        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(equalTo: anchor, constant: constant)
        urlTextFieldLeadingConstraint?.isActive = true
    }

    private func updateWidthConstraint(
        _ constraint: inout NSLayoutConstraint?,
        for view: UIView,
        to widthConstant: CGFloat
    ) {
        constraint?.isActive = false
        constraint = view.widthAnchor.constraint(equalToConstant: widthConstant)
        constraint?.isActive = true
    }

    private func addSearchEngineButton() {
        iconContainerStackView.addArrangedSubview(searchEngineContentView)
    }

    private func addLockIconImageView() {
        iconContainerStackView.addArrangedSubview(lockIconImageView)
    }

    private func removeContainerIcons() {
        iconContainerStackView.removeAllArrangedViews()
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ state: LocationViewState) {
        urlTextField.text = state.url
        urlTextField.placeholder = state.urlTextFieldPlaceholder
        urlAbsolutePath = urlTextField.text
    }

    private func formatAndTruncateURLTextField() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let urlString = urlAbsolutePath ?? ""
        let (subdomain, normalizedHost) = URL.getSubdomainAndHost(from: urlString)

        let attributedString = NSMutableAttributedString(string: normalizedHost)

        if let subdomain {
            let range = NSRange(location: 0, length: subdomain.count)
            attributedString.addAttribute(.foregroundColor, value: urlTextFieldSubdomainColor, range: range)
        }
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(
                location: 0,
                length: attributedString.length
            )
        )
        urlTextField.attributedText = attributedString
    }

    private func animateURLText(
        _ textField: UITextField,
        options: UIView.AnimationOptions,
        textAlignment: NSTextAlignment,
        completion: (() -> Void)? = nil
    ) {
        UIView.transition(
            with: textField,
            duration: UX.transitionDuration,
            options: options) {
            textField.textAlignment = textAlignment
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - Selectors
    @objc
    func textDidChange(_ textField: UITextField) {
        notifyTextChanged?()
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        removeContainerIcons()

        updateWidthConstraint(
            &iconContainerStackViewWidthConstraint,
            for: iconContainerStackView,
            to: UX.searchEngineImageViewSize.width
        )
        updateURLTextFieldLeadingConstraint(
            equalTo: iconContainerStackView.trailingAnchor,
            constant: UX.horizontalSpace
        )

        if !isURLTextFieldEmpty {
            animateURLText(textField, options: .transitionFlipFromBottom, textAlignment: .natural)
        }
        addSearchEngineButton()
        updateGradient()

        let url = URL(string: textField.text ?? "")
        let queryText = locationViewDelegate?.locationViewDisplayTextForURL(url)

        DispatchQueue.main.async { [self] in
            // `attributedText` property is set to nil to remove all formatting and truncation set before.
            textField.attributedText = nil
            textField.text = (queryText != nil) ? queryText : urlAbsolutePath
            textField.selectAll(nil)
        }
        locationViewDelegate?.locationViewDidBeginEditing(textField.text ?? "")
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        if !isURLTextFieldEmpty {
            updateWidthConstraint(&iconContainerStackViewWidthConstraint, for: iconContainerStackView, to: UX.lockIconWidth)
            removeContainerIcons()
            addLockIconImageView()
        }
        updateGradient()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Accessibility
    private func configureA11y(_ state: LocationViewState) {
        searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentTitle = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentImage = nil

        urlTextField.accessibilityIdentifier = state.urlTextFieldA11yId
        urlTextField.accessibilityLabel = state.urlTextFieldA11yLabel
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        urlTextFieldSubdomainColor = colors.textSecondary
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
        searchEngineImageView.backgroundColor = colors.iconPrimary
        lockIconImageView.tintColor = colors.iconPrimary
        lockIconImageView.backgroundColor = colors.layerSearch
        urlTextField.applyTheme(theme: theme)
    }
}
