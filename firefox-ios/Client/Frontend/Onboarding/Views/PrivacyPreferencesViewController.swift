// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

final class PrivacyPreferencesViewController: UIViewController,
                                              Themeable,
                                              Notifiable {
    struct UX {
        static let headerViewTopMargin: CGFloat = 10
        static let horizontalMargin: CGFloat = 10
        static let contentHorizontalMargin: CGFloat = 24
        static let contentDistance: CGFloat = 24
    }

    // MARK: - Properties
    var windowUUID: WindowUUID
    var themeManager: ThemeManager
    var themeObserver: (any NSObjectProtocol)?
    var currentWindowUUID: UUID? { windowUUID }
    var notificationCenter: NotificationProtocol

    // MARK: - UI elements
    private var headerView: HeaderView = .build()

    private lazy var contentScrollView: UIScrollView = .build()

    private lazy var contentView: UIView = .build()

    private lazy var crashReportsSwitch: SwitchDetailedView = .build()

    private lazy var technicalDataSwitch: SwitchDetailedView = .build()

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self, observing: [.DynamicFontChanged])
        setupLayout()
        setDetentSize()
        setupHeaderView()
        setupContentViews()
        setupCallbacks()
        setupAccessibility()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
    }

    // MARK: - View setup
    private func setupLayout() {
        view.addSubview(headerView)
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        contentView.addSubview(crashReportsSwitch)
        contentView.addSubview(technicalDataSwitch)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.headerViewTopMargin),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.horizontalMargin),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.horizontalMargin),

            contentScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor).priority(.defaultLow),

            crashReportsSwitch.topAnchor.constraint(equalTo: contentView.topAnchor),
            crashReportsSwitch.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: UX.contentHorizontalMargin
            ),
            crashReportsSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -UX.contentHorizontalMargin
            ),

            technicalDataSwitch.topAnchor.constraint(
                equalTo: crashReportsSwitch.bottomAnchor,
                constant: UX.contentDistance
            ),
            technicalDataSwitch.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: UX.contentHorizontalMargin
            ),
            technicalDataSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -UX.contentHorizontalMargin
            ),
            technicalDataSwitch.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -UX.contentDistance)
        ])
    }

    private func setupHeaderView() {
        headerView.updateHeaderLineView(isHidden: true)
        headerView.setupDetails(title: .Onboarding.TermsOfService.PrivacyPreferences.Title,
                                doneText: .SettingsSearchDoneButton)
        headerView.adjustLayout(shouldHideIcon: true, shouldUseDoneButton: true)
        headerView.closeButtonCallback = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func setupContentViews() {
        crashReportsSwitch.setupDetails(
            actionTitle: .Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsTitle,
            actionDescription: .Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsDescription,
            linkDescription: .Onboarding.TermsOfService.PrivacyPreferences.LearnMore,
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )
        technicalDataSwitch.setupDetails(
            actionTitle: .Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataTitle,
            actionDescription: .Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataDescription,
            linkDescription: .Onboarding.TermsOfService.PrivacyPreferences.LearnMore,
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )
    }

    private func setupCallbacks() {
        // TODO: FXIOS-10675 Firefox iOS: Manage Privacy Preferences during Onboarding - Logic
        crashReportsSwitch.switchCallback = { _ in }
        technicalDataSwitch.switchCallback = { _ in }

        // TODO: FXIOS-10638 Firefox iOS: Use the correct Terms of Service and Privacy Notice URLs in ToSViewController
        crashReportsSwitch.learnMoreCallBack = { [weak self] in
            self?.presentLink(with: nil)
        }
        technicalDataSwitch.learnMoreCallBack = { [weak self] in
            self?.presentLink(with: nil)
        }
    }

    private func setupAccessibility() {
        headerView.setupAccessibility(doneButtonA11yId: AccessibilityIdentifiers.TermsOfService.PrivacyNotice.doneButton,
                                      titleA11yId: AccessibilityIdentifiers.TermsOfService.PrivacyNotice.title)

        let identifiers = AccessibilityIdentifiers.TermsOfService.PrivacyNotice.self
        let crashReportViewModel = SwitchDetailedViewModel(
            contentStackViewA11yId: identifiers.CrashReports.contentStackView,
            actionContentViewA11yId: identifiers.CrashReports.actionContentView,
            actionTitleLabelA11yId: identifiers.CrashReports.actionTitleLabel,
            actionSwitchA11yId: identifiers.CrashReports.actionSwitch,
            actionDescriptionLabelA11yId: identifiers.CrashReports.actionDescriptionLabel
        )
        crashReportsSwitch.configure(viewModel: crashReportViewModel)

        let technicalDataViewModel = SwitchDetailedViewModel(
            contentStackViewA11yId: identifiers.TechnicalData.contentStackView,
            actionContentViewA11yId: identifiers.TechnicalData.actionContentView,
            actionTitleLabelA11yId: identifiers.TechnicalData.actionTitleLabel,
            actionSwitchA11yId: identifiers.TechnicalData.actionSwitch,
            actionDescriptionLabelA11yId: identifiers.TechnicalData.actionDescriptionLabel
        )
        technicalDataSwitch.configure(viewModel: technicalDataViewModel)
    }

    private func setDetentSize() {
        if UIDevice.current.userInterfaceIdiom == .phone, let sheet = sheetPresentationController {
            if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                sheet.detents = [.large()]
            } else {
                sheet.detents = [.medium()]
            }
        }
    }

    private func presentLink(with url: URL?) {
        guard let url else { return }
        let presentLinkVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissPresentedLinkVC))
        buttonItem.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.doneButton

        presentLinkVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: presentLinkVC)
        present(controller, animated: true)
    }

    // MARK: - Button actions
    @objc
    private func dismissPresentedLinkVC() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            setDetentSize()
        default: break
        }
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
        headerView.applyTheme(theme: theme)
        crashReportsSwitch.applyTheme(theme: theme)
        technicalDataSwitch.applyTheme(theme: theme)
        setupContentViews()
    }
}
