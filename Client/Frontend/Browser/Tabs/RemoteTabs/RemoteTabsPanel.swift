// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Account
import Shared
import SnapKit
import Storage
import Sync

protocol RemotePanelDelegate: AnyObject {
    func remotePanelDidRequestToSignIn()
    func remotePanelDidRequestToCreateAccount()
    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func remotePanel(didSelectURL url: URL, visitType: VisitType)
}

// MARK: - RemoteTabsPanel
class RemoteTabsPanel: UIViewController, Themeable, Loggable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var remotePanelDelegate: RemotePanelDelegate?
    var profile: Profile
    lazy var tableViewController = RemoteTabsTableViewController()

    init(profile: Profile,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .FirefoxAccountChanged,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .ProfileDidFinishSyncing,
                                       object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewController.profile = profile
        tableViewController.remoteTabsPanel = self
        addChild(tableViewController)
        self.view.addSubview(tableViewController.view)

        tableViewController.view.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.view)
        }

        tableViewController.didMove(toParent: self)
        listenForThemeChange()
        applyTheme()
    }

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer4
        tableViewController.tableView.backgroundColor =  themeManager.currentTheme.colors.layer3
        tableViewController.tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableViewController.tableView.reloadData()
        tableViewController.refreshTabs()
    }

    func forceRefreshTabs() {
        tableViewController.refreshTabs(updateCache: true)
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .ProfileDidFinishSyncing:
            DispatchQueue.main.async {
                self.tableViewController.refreshTabs()
            }
            break
        default:
            // no need to do anything at all
            browserLog.warning("Received unexpected notification \(notification.name)")
            break
        }
    }
}

enum RemoteTabsError {
    case notLoggedIn
    case noClients
    case noTabs
    case failedToSync

    func localizedString() -> String {
        switch self {
        case .notLoggedIn: return .EmptySyncedTabsPanelNotSignedInStateDescription
        case .noClients: return .EmptySyncedTabsPanelNullStateDescription
        case .noTabs: return .RemoteTabErrorNoTabs
        case .failedToSync: return .RemoteTabErrorFailedToSync
        }
    }
}

protocol RemoteTabsPanelDataSource: UITableViewDataSource, UITableViewDelegate {
}

protocol CollapsibleTableViewSection: AnyObject {
    func hideTableViewSection(_ section: Int)
}

// MARK: - RemoteTabsPanelClientAndTabsDataSource
class RemoteTabsPanelClientAndTabsDataSource: NSObject, RemoteTabsPanelDataSource {
    struct UX {
        static let headerHeight = SiteTableViewControllerUX.RowHeight
        static let iconBorderColor = UIColor.Photon.Grey30
        static let iconBorderWidth: CGFloat = 0.5
    }

    weak var collapsibleSectionDelegate: CollapsibleTableViewSection?
    weak var remoteTabPanel: RemoteTabsPanel?
    var clientAndTabs: [ClientAndTabs]
    var hiddenSections = Set<Int>()
    private let siteImageHelper: SiteImageHelper
    private var theme: Theme

    init(remoteTabPanel: RemoteTabsPanel,
         clientAndTabs: [ClientAndTabs],
         profile: Profile,
         theme: Theme) {
        self.remoteTabPanel = remoteTabPanel
        self.clientAndTabs = clientAndTabs
        self.siteImageHelper = SiteImageHelper(profile: profile)
        self.theme = theme
    }

    @objc private func sectionHeaderTapped(sender: UIGestureRecognizer) {
        guard let section = sender.view?.tag else { return }
        collapsibleSectionDelegate?.hideTableViewSection(section)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.clientAndTabs.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hiddenSections.contains(section) {
            return 0
        }

        return self.clientAndTabs[section].tabs.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SiteTableViewHeader.cellIdentifier) as? SiteTableViewHeader else { return nil }
        let clientTabs = self.clientAndTabs[section]
        let client = clientTabs.client

        let isCollapsed = hiddenSections.contains(section)
        let viewModel = SiteTableViewHeaderModel(title: client.name,
                                                 isCollapsible: true,
                                                 collapsibleState:
                                                    isCollapsed ? ExpandButtonState.right : ExpandButtonState.down)
        headerView.configure(viewModel)
        headerView.showBorder(for: .bottom, true)
        headerView.showBorder(for: .top, section != 0)

        // Configure tap to collapse/expand section
        headerView.tag = section
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sectionHeaderTapped(sender:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.applyTheme(theme: theme)
        /*
        * A note on timestamps.
        * We have access to two timestamps here: the timestamp of the remote client record,
        * and the set of timestamps of the client's tabs.
        * Neither is "last synced". The client record timestamp changes whenever the remote
        * client uploads its record (i.e., infrequently), but also whenever another device
        * sends a command to that client -- which can be much later than when that client
        * last synced.
        * The client's tabs haven't necessarily changed, but it can still have synced.
        * Ideally, we should save and use the modified time of the tabs record itself.
        * This will be the real time that the other client uploaded tabs.
        */
        return headerView
    }

    func tabAtIndexPath(_ indexPath: IndexPath) -> RemoteTab {
        return clientAndTabs[indexPath.section].tabs[indexPath.item]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
                                                       for: indexPath) as? TwoLineImageOverlayCell
        else {
            return UITableViewCell()
        }

        let tab = tabAtIndexPath(indexPath)
        cell.titleLabel.text = tab.title
        cell.descriptionLabel.text = tab.URL.absoluteString

        cell.leftImageView.layer.borderColor = UX.iconBorderColor.cgColor
        cell.leftImageView.layer.borderWidth = UX.iconBorderWidth
        cell.accessoryView = nil

        getFavicon(for: tab) { [weak cell] image in
            cell?.leftImageView.image = image
            cell?.leftImageView.backgroundColor = .clear
        }

        cell.applyTheme(theme: theme)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let tab = tabAtIndexPath(indexPath)
        // Remote panel delegate for cell selection
        remoteTabPanel?.remotePanelDelegate?.remotePanel(didSelectURL: tab.URL, visitType: VisitType.typed)
    }

    private func getFavicon(for remoteTab: RemoteTab, completion: @escaping (UIImage?) -> Void) {
        let faviconUrl = remoteTab.URL.absoluteString
        let site = Site(url: faviconUrl, title: remoteTab.title)
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }
}

// MARK: - RemoteTabsTableViewController
class RemoteTabsTableViewController: UITableViewController, Themeable {
    struct UX {
        static let rowHeight = SiteTableViewControllerUX.RowHeight

    }

    weak var remoteTabsPanel: RemoteTabsPanel?
    var profile: Profile!
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var tableViewDelegate: RemoteTabsPanelDataSource? {
        didSet {
            tableView.dataSource = tableViewDelegate
            tableView.delegate = tableViewDelegate
        }
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.register(SiteTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)

        tableView.rowHeight = UX.rowHeight
        tableView.separatorInset = .zero

        tableView.tableFooterView = UIView() // prevent extra empty rows at end
        tableView.delegate = nil
        tableView.dataSource = nil

        tableView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncedTabs
        listenForThemeChange()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()

        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control.
        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        }

        refreshTabs(updateCache: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.layerLightGrey30
        if let delegate = tableViewDelegate as? RemoteTabsPanelErrorDataSource {
            delegate.applyTheme(theme: themeManager.currentTheme)
        }
    }

    // MARK: - Refreshing TableView

    func addRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(onRefreshPulled), for: .valueChanged)
        refreshControl = control
        tableView.refreshControl = control
    }

    func removeRefreshControl() {
        tableView.refreshControl = nil
        refreshControl = nil
    }

    @objc func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        refreshTabs(updateCache: true)
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !profile.hasSyncableAccount() {
            removeRefreshControl()
        }
    }

    func updateDelegateClientAndTabData(_ clientAndTabs: [ClientAndTabs]) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }

        guard !clientAndTabs.isEmpty else {
            tableViewDelegate = RemoteTabsPanelErrorDataSource(remoteTabsPanel: remoteTabsPanel,
                                                                    error: .noClients,
                                                                    theme: themeManager.currentTheme)
            tableView.reloadData()
            return
        }

        let nonEmptyClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty }
        if nonEmptyClientAndTabs.isEmpty {
            tableViewDelegate = RemoteTabsPanelErrorDataSource(remoteTabsPanel: remoteTabsPanel,
                                                                    error: .noTabs,
                                                                    theme: themeManager.currentTheme)
        } else {
            let tabsPanelDataSource = RemoteTabsPanelClientAndTabsDataSource(remoteTabPanel: remoteTabsPanel,
                                                                             clientAndTabs: nonEmptyClientAndTabs,
                                                                             profile: profile,
                                                                             theme: themeManager.currentTheme)
            tabsPanelDataSource.collapsibleSectionDelegate = self
            tableViewDelegate = tabsPanelDataSource
        }
        tableView.reloadData()
    }

    func refreshTabs(updateCache: Bool = false, completion: (() -> Void)? = nil) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }

        assert(Thread.isMainThread)

        // Short circuit if the user is not logged in
        guard profile.hasSyncableAccount() else {
            self.endRefreshing()
            self.tableViewDelegate = RemoteTabsPanelErrorDataSource(remoteTabsPanel: remoteTabsPanel,
                                                                    error: .notLoggedIn,
                                                                    theme: themeManager.currentTheme)
            return
        }

        // Get cached tabs.
        self.profile.getCachedClientsAndTabs().uponQueue(.main) { result in
            guard let clientAndTabs = result.successValue else {
                self.endRefreshing()
                self.tableViewDelegate = RemoteTabsPanelErrorDataSource(remoteTabsPanel: remoteTabsPanel,
                                                                        error: .failedToSync,
                                                                        theme: self.themeManager.currentTheme)
                return
            }

            // Update UI with cached data.
            self.updateDelegateClientAndTabData(clientAndTabs)

            if updateCache {
                // Fetch updated tabs.
                self.profile.getClientsAndTabs().uponQueue(.main) { result in
                    if let clientAndTabs = result.successValue {
                        // Update UI with updated tabs.
                        self.updateDelegateClientAndTabData(clientAndTabs)
                    }

                    self.endRefreshing()
                    completion?()
                }
            } else {
                self.endRefreshing()
                completion?()
            }
        }
    }

    @objc private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }
}

extension RemoteTabsTableViewController: CollapsibleTableViewSection {
    func hideTableViewSection(_ section: Int) {
        guard let dataSource = tableViewDelegate as? RemoteTabsPanelClientAndTabsDataSource else { return }

        if dataSource.hiddenSections.contains(section) {
            dataSource.hiddenSections.remove(section)
        } else {
            dataSource.hiddenSections.insert(section)
        }

        tableView.reloadData()
    }
}

// MARK: LibraryPanelContextMenu
extension RemoteTabsTableViewController: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath,
                            completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let tab = (tableViewDelegate as? RemoteTabsPanelClientAndTabsDataSource)?.tabAtIndexPath(indexPath) else {
            return nil
        }
        return Site(url: String(describing: tab.URL), title: tab.title)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        return getRemoteTabContexMenuActions(for: site, remotePanelDelegate: remoteTabsPanel?.remotePanelDelegate)
    }
}
