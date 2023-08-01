// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct CollapsibleCardContainerModel {
    public let contentView: UIView
    public let cardViewA11yId: String

    public let title: String
    public let titleA11yId: String

    public let expandButtonA11yId: String
    public let expandButtonA11yLabelExpanded: String
    public let expandButtonA11yLabelCollapsed: String

    public var expandState: CollapsibleCardContainer.ExpandButtonState = .collapsed

    public var expandButtonA11yLabel: String {
        return expandState == .expanded ? expandButtonA11yLabelExpanded : expandButtonA11yLabelCollapsed
    }

    public init(contentView: UIView,
                cardViewA11yId: String,
                title: String,
                titleA11yId: String,
                expandButtonA11yId: String,
                expandButtonA11yLabelExpanded: String,
                expandButtonA11yLabelCollapsed: String,
                expandState: CollapsibleCardContainer.ExpandButtonState = .collapsed) {
        self.contentView = contentView
        self.cardViewA11yId = cardViewA11yId
        self.title = title
        self.titleA11yId = titleA11yId
        self.expandButtonA11yId = expandButtonA11yId
        self.expandButtonA11yLabelExpanded = expandButtonA11yLabelExpanded
        self.expandButtonA11yLabelCollapsed = expandButtonA11yLabelCollapsed
        self.expandState = expandState
    }
}

public class CollapsibleCardContainer: CardContainer, UIGestureRecognizerDelegate {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let titleHorizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 16
        static let expandButtonSize = CGSize(width: 20, height: 20)
    }

    public enum ExpandButtonState {
        case collapsed
        case expanded

        var image: UIImage? {
            switch self {
            case .expanded:
                return UIImage(named: StandardImageIdentifiers.Large.chevronUp)?.withRenderingMode(.alwaysTemplate)
            case .collapsed:
                return UIImage(named: StandardImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate)
            }
        }

        var toggle: ExpandButtonState {
            switch self {
            case .expanded:
                return .collapsed
            case .collapsed:
                return .expanded
            }
        }
    }

    // MARK: - Properties
    private lazy var viewModel = CollapsibleCardContainerModel(
        contentView: rootView,
        cardViewA11yId: "",
        title: "",
        titleA11yId: "",
        expandButtonA11yId: "",
        expandButtonA11yLabelExpanded: "",
        expandButtonA11yLabelCollapsed: "",
        expandState: .collapsed)

    // UI
    private lazy var rootView: UIView = .build { _ in }
    private lazy var headerView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }
    private var containerHeightConstraint: NSLayoutConstraint?
    private var tapRecognizer: UITapGestureRecognizer!

    lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline, size: 17.0)
        label.numberOfLines = 0
    }

    private lazy var expandButton: UIButton = .build { view in
        view.setImage(self.viewModel.expandState.image, for: .normal)
        view.addTarget(self, action: #selector(self.toggleExpand), for: .touchUpInside)
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHeader))
        tapRecognizer.delegate = self
        headerView.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func configure(_ viewModel: CardContainerModel) {
        // the overridden method should not be used as it is lacking vital details to configure this card
        fatalError("configure(:) has not been implemented.")
    }

    public func configure(_ viewModel: CollapsibleCardContainerModel) {
        self.viewModel = viewModel
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.addSubview(viewModel.contentView)

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId
        expandButton.accessibilityIdentifier = viewModel.expandButtonA11yId
        expandButton.accessibilityLabel = viewModel.expandButtonA11yLabel

        NSLayoutConstraint.activate([
            viewModel.contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            viewModel.contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewModel.contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            viewModel.contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        updateCardState(expandState: viewModel.expandState)

        let parentViewModel = CardContainerModel(view: rootView, a11yId: viewModel.cardViewA11yId)
        super.configure(parentViewModel)
    }

    public override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textPrimary
        expandButton.tintColor = theme.colors.iconPrimary
        (viewModel.contentView as? ThemeApplicable)?.applyTheme(theme: theme)
    }

    private func setupLayout() {
        configure(viewModel)

        headerView.addSubview(titleLabel)
        headerView.addSubview(expandButton)
        rootView.addSubview(headerView)
        rootView.addSubview(containerView)

        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                constant: UX.titleHorizontalPadding),
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor,
                                            constant: UX.titleTopPadding),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                 constant: -UX.titleHorizontalPadding),
            headerView.bottomAnchor.constraint(equalTo: containerView.topAnchor,
                                               constant: -UX.verticalPadding),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.expandButtonSize.height),

            expandButton.topAnchor.constraint(greaterThanOrEqualTo: headerView.topAnchor),
            expandButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            expandButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),
            expandButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: UX.expandButtonSize.width),
            expandButton.heightAnchor.constraint(equalToConstant: UX.expandButtonSize.height),

            containerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                   constant: UX.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                    constant: -UX.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor,
                                                  constant: -UX.verticalPadding),
        ])
    }

    private func updateCardState(expandState: ExpandButtonState) {
        viewModel.expandState = expandState
        expandButton.setImage(viewModel.expandState.image, for: .normal)
        expandButton.accessibilityLabel = viewModel.expandButtonA11yLabel
        containerHeightConstraint?.isActive = expandState == .collapsed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    @objc
    private func toggleExpand(_ sender: UIButton) {
        updateCardState(expandState: viewModel.expandState.toggle)
    }

    @objc
    func tapHeader(_ recognizer: UITapGestureRecognizer) {
        updateCardState(expandState: viewModel.expandState.toggle)
    }
}
