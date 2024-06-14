// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

import enum MozillaAppServices.VisitType

protocol RemoteTabsPanelDelegate: AnyObject {
    func presentFirefoxAccountSignIn()
    func presentFxAccountSettings()
}

class RemoteTabsPanel: UIViewController,
                       Themeable,
                       RemoteTabsClientAndTabsDataSourceDelegate,
                       RemoteTabsEmptyViewDelegate,
                       StoreSubscriber {
    typealias SubscriberStateType = RemoteTabsPanelState

    // MARK: - Properties

    private(set) var state: RemoteTabsPanelState
    var tableViewController: RemoteTabsTableViewController
    weak var remoteTabsDelegate: RemoteTabsPanelDelegate?

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    private let windowUUID: WindowUUID

    // MARK: - Initializer

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.state = RemoteTabsPanelState(windowUUID: windowUUID)
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tableViewController = RemoteTabsTableViewController(state: state, windowUUID: windowUUID)

        super.init(nibName: nil, bundle: nil)

        self.tableViewController.remoteTabsPanel = self
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        unsubscribeFromRedux()
    }

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Actions

    func tableViewControllerDidPullToRefresh() {
        refreshTabs()
    }

    // MARK: - Internal Utilities

    private func refreshTabs() {
        // Ensure we do not already have a refresh in progress
        guard state.refreshState != .refreshing else { return }
        let action = RemoteTabsPanelAction(windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.refreshTabs)
        store.dispatch(action)
    }

    // MARK: - View & Layout

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupLayout()
        subscribeToRedux()
        applyTheme()
    }

    private func setupLayout() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(tableViewController)
        view.addSubview(tableViewController.view)
        tableViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func applyTheme() {
        let theme = themeManager.getcurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer4
        tableViewController.tableView.backgroundColor =  theme.colors.layer3
        tableViewController.tableView.separatorColor = theme.colors.borderPrimary
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let showScreenAction = ScreenAction(windowUUID: windowUUID,
                                            actionType: ScreenActionType.showScreen,
                                            screen: .remoteTabsPanel)
        store.dispatch(showScreenAction)

        let didAppearAction = RemoteTabsPanelAction(windowUUID: windowUUID,
                                                    actionType: RemoteTabsPanelActionType.panelDidAppear)
        store.dispatch(didAppearAction)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return RemoteTabsPanelState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .remoteTabsPanel)
        store.dispatch(action)
    }

    func newState(state: RemoteTabsPanelState) {
        ensureMainThread { [weak self] in
            guard let self else { return }

            self.state = state
            tableViewController.newState(state: state)
        }
    }

    // MARK: - RemoteTabsClientAndTabsDataSourceDelegate
    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType) {
        handleOpenSelectedURL(url)
    }

    // MARK: - RemotePanelDelegate
    func remotePanelDidRequestToSignIn() {
        remoteTabsDelegate?.presentFirefoxAccountSignIn()
    }

    func presentFxAccountSettings() {
        remoteTabsDelegate?.presentFxAccountSettings()
    }

    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        handleOpenSelectedURL(url)
    }

    func remotePanel(didSelectURL url: URL, visitType: VisitType) {
        handleOpenSelectedURL(url)
    }

    private func handleOpenSelectedURL(_ url: URL) {
        let action = RemoteTabsPanelAction(url: url,
                                           windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.openSelectedURL)
        store.dispatch(action)
    }
}
