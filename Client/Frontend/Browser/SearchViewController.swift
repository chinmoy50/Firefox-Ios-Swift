/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import MozillaAppServices
import Telemetry

private enum SearchListSection: Int, CaseIterable {
    case searchSuggestions
    case bookmarksAndHistory
    case remoteTabs
    case openedTabs
}

private struct SearchViewControllerUX {
    static var SearchEngineScrollViewBackgroundColor: CGColor { return UIColor.theme.homePanel.toolbarBackground.withAlphaComponent(0.8).cgColor }
    static let SearchEngineScrollViewBorderColor = UIColor.black.withAlphaComponent(0.2).cgColor

    // TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
    static let EngineButtonHeight: Float = 44
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = "search"
    static let SearchAppendImage = "search-append"
    static let SearchEngineTopBorderWidth = 0.5
    static let SuggestionMargin: CGFloat = 8

    static let IconSize: CGFloat = 23
    static let FaviconSize: CGFloat = 29
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

protocol SearchViewControllerDelegate: AnyObject {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL)
    func searchViewController(_ searchViewController: SearchViewController, switchToTabWithUrl url: URL, with uuid: String, isPrivate: Bool)
    func searchViewController(_ searchViewController: SearchViewController, uuid: String)
    func presentSearchSettingsController()
    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool)
    func searchViewController(_ searchViewController: SearchViewController, didAppend text: String)
}

struct ClientTabsSearchWrapper {
    var client: RemoteClient
    var tab: RemoteTab
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    fileprivate let isPrivate: Bool
    fileprivate var suggestClient: SearchSuggestClient?
    var clientAndTabs: [ClientAndTabs] = [ClientAndTabs]()
//    var remoteTabs = [RemoteTab]()
    var filteredRemoteTabs = [RemoteTab]()
    var filteredClientRemoteTabs = [ClientAndTabs]()
    var remoteClientTabsWrapper = [ClientTabsSearchWrapper]()
    var filteredRemoteClientTabsWrapper = [ClientTabsSearchWrapper]()
    var openedTabs = [Tab]()
    var filteredOpenedTabs = [Tab]()
    var tabManager: TabManager
    
    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    fileprivate let searchEngineContainerView = UIView()
    fileprivate let searchEngineScrollView = ButtonScrollView()
    fileprivate let searchEngineScrollViewContent = UIView()

    fileprivate lazy var bookmarkedBadge: UIImage = {
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
//        return UIImage(named: "switch_tab_light")!
        return theme == .dark ? UIImage(named: "bookmark_results_dark")! : UIImage(named: "bookmark_results_light")!
//        return UIImage.templateImageNamed("bookmarked_passive")!.tinted(withColor: .lightGray).createScaled(CGSize(width: 16, height: 16))
    }()
    
    fileprivate lazy var switchAndSyncTabBadge: UIImage = {
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
        return theme == .dark ? UIImage(named: "switch_tab_dark")! : UIImage(named: "switch_tab_light")!
//        return theme == .normal ? UIImage(named: "switch_tab_dark")! : UIImage(named: "switch_tab_light")!
//        return UIImage.templateImageNamed("bookmarked_passive")!.tinted(withColor: .lightGray).createScaled(CGSize(width: 16, height: 16))
    }()

    var suggestions: [String]? = []
    static var userAgent: String?

    
    init(profile: Profile, isPrivate: Bool, tabManager: TabManager) {
        self.isPrivate = isPrivate
        self.tabManager = tabManager
        super.init(profile: profile)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blur)

        super.viewDidLoad()
        getCachedTabs()
        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineContainerView.layer.backgroundColor = SearchViewControllerUX.SearchEngineScrollViewBackgroundColor
        searchEngineContainerView.layer.shadowRadius = 0
        searchEngineContainerView.layer.shadowOpacity = 100
        searchEngineContainerView.layer.shadowOffset = CGSize(width: 0, height: -SearchViewControllerUX.SearchEngineTopBorderWidth)
        searchEngineContainerView.layer.shadowColor = SearchViewControllerUX.SearchEngineScrollViewBorderColor
        searchEngineContainerView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        searchEngineContainerView.addSubview(searchEngineScrollView)
        view.addSubview(searchEngineContainerView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clear.cgColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp.makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priority(10)
            //left-align the engines on iphones, center on ipad
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                make.left.equalTo(self.searchEngineScrollView).priority(1000)
            } else {
                make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            }
            make.right.lessThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            make.top.equalTo(self.searchEngineScrollView)
            make.bottom.equalTo(self.searchEngineScrollView)
        }

        blur.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    
        searchEngineContainerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
    }

    @objc func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSearchEngines()
        reloadData()
    }

    fileprivate func layoutSearchEngineScrollView() {
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
        searchEngineScrollView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            if keyboardHeight == 0 {
                make.bottom.equalTo(view.safeArea.bottom)
            } else {
                make.bottom.equalTo(view).offset(-keyboardHeight)
            }
        }
    }

    var searchEngines: SearchEngines! {
        didSet {
            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            if !isPrivate {
                let ua = SearchViewController.userAgent ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine, userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()
        }
    }

    fileprivate var quickSearchEngines: [OpenSearchEngine] {
        var engines = searchEngines.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if isPrivate || !searchEngines.shouldShowSearchSuggestions {
            engines?.insert(searchEngines.defaultEngine, at: 0)
        }

        return engines!
    }

    var searchQuery: String = "" {
        didSet {
            // Reload the tableView to show the updated text in each engine.
            reloadData()
        }
    }

    override func reloadData() {
        querySuggestClient()
    }

    fileprivate func layoutTable() {
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(self.view.snp.top)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.searchEngineScrollView.snp.top)
        }
    }

    func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.snp.left

        //search settings icon
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "quickSearch"), for: [])
        searchButton.imageView?.contentMode = .center
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        searchButton.accessibilityLabel = String(format: .SearchSettingsAccessibilityLabel)

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.size.equalTo(SearchViewControllerUX.FaviconSize)
            //offset the left edge to align with search results
            make.left.equalTo(leftEdge).offset(SearchViewControllerUX.SuggestionMargin * 2)
            make.top.equalTo(self.searchEngineScrollViewContent).offset(SearchViewControllerUX.SuggestionMargin)
            make.bottom.equalTo(self.searchEngineScrollViewContent).offset(-SearchViewControllerUX.SuggestionMargin)
        }

        //search engines
        leftEdge = searchButton.snp.right
        for engine in quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.imageView?.layer.cornerRadius = 4
            engineButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(didSelectEngine), for: .touchUpInside)
            engineButton.accessibilityLabel = String(format: .SearchSearchEngineAccessibilityLabel, engine.shortName)

            engineButton.imageView?.snp.makeConstraints { make in
                make.width.height.equalTo(SearchViewControllerUX.FaviconSize)
                return
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp.makeConstraints { make in
                make.width.equalTo(SearchViewControllerUX.EngineButtonWidth)
                make.height.equalTo(SearchViewControllerUX.EngineButtonHeight)
                make.left.equalTo(leftEdge)
                make.top.equalTo(self.searchEngineScrollViewContent)
                make.bottom.equalTo(self.searchEngineScrollViewContent)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent)
                }
            }
            leftEdge = engineButton.snp.right
        }
    }

    @objc func didSelectEngine(_ sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        // Subtract 1 from index to account for magnifying glass accessory.
        guard let index = searchEngineScrollViewContent.subviews.firstIndex(of: sender) else {
            assertionFailure()
            return
        }

        let engine = quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(searchQuery) else {
            assertionFailure()
            return
        }

        Telemetry.default.recordSearch(location: .quickSearch, searchEngine: engine.engineID ?? "other")
        GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.quickSearch.rawValue)"].add()

        searchDelegate?.searchViewController(self, didSelectURL: url)
    }

    @objc func didClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The height of the suggestions row may change, so call reloadData() to recalculate cell heights.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        }, completion: nil)
    }

    fileprivate func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        layoutSearchEngineScrollView()

        UIView.animate(withDuration: keyboardState.animationDuration, animations: {
            UIView.setAnimationCurve(keyboardState.animationCurve)
            self.view.layoutIfNeeded()
        })
    }
    
    
    fileprivate func getCachedTabs() {
        assert(Thread.isMainThread)

        // Short circuit if the user is not logged in
        guard profile.hasSyncableAccount() else {
            return
        }

        // Get cached tabs.
        self.profile.getCachedClientsAndTabs().uponQueue(.main) { result in
            guard let clientAndTabs = result.successValue else {
                return
            }

            self.remoteClientTabsWrapper.removeAll()
            // Update UI with cached data.
            self.clientAndTabs = clientAndTabs
            clientAndTabs.forEach { value in
                value.tabs.forEach { (tab) in
                    self.remoteClientTabsWrapper.append(ClientTabsSearchWrapper(client: value.client, tab: tab))
                }
            }
        }
    }
    
    func searchTabs(for searchString: String) {
        let currentTabs = self.isPrivate ? self.tabManager.privateTabs : self.tabManager.normalTabs
        filteredOpenedTabs = currentTabs.filter { tab in
            if let url = tab.url, InternalURL.isValid(url: url) {
                return false
            }
            let title = tab.title ?? tab.lastTitle
            if title?.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            if tab.url?.absoluteString.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            return false
        }
    }
    
    func searchRemoteTabs(for searchString: String) {
        
        filteredRemoteClientTabsWrapper.removeAll()
        for remoteClientTab in remoteClientTabsWrapper {
            if remoteClientTab.tab.title.lowercased().contains(searchQuery) {
                filteredRemoteClientTabsWrapper.append(remoteClientTab)
            }
        }
        
        
        let currentTabs = self.remoteClientTabsWrapper
        self.filteredRemoteClientTabsWrapper = currentTabs.filter { value in
            let tab = value.tab
            if InternalURL.isValid(url: tab.URL) {
                return false
            }
            if tab.title.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            if tab.URL.absoluteString.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            return false
        }
    }
    
    fileprivate func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty || !searchEngines.shouldShowSearchSuggestions || searchQuery.looksLikeAURL() {
            suggestions = []
            tableView.reloadData()
            return
        }
        
        searchTabs(for: searchQuery)
        searchRemoteTabs(for: searchQuery)
        suggestClient?.query(searchQuery, callback: { suggestions, error in
            if let error = error {
                let isSuggestClientError = error.domain == SearchSuggestClientErrorDomain

                switch error.code {
                case NSURLErrorCancelled where error.domain == NSURLErrorDomain:
                    // Request was cancelled. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidEngine where isSuggestClientError:
                    // Engine does not support search suggestions. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidResponse where isSuggestClientError:
                    print("Error: Invalid search suggestion data")
                default:
                    print("Error: \(error.description)")
                }
            } else {
                self.suggestions = suggestions!
                 // First suggestion should be what the user is searching
                self.suggestions?.insert(self.searchQuery, at: 0)
            }

            // If there are no suggestions, just use whatever the user typed.
            if suggestions?.isEmpty ?? true {
                self.suggestions = [self.searchQuery]
            }

            // Reload the tableView to show the new list of search suggestions.
            self.tableView.reloadData()
        })
    }

    func loader(dataLoaded data: Cursor<Site>) {
        self.data = data
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SearchListSection(rawValue: indexPath.section)! {
        case .searchSuggestions:
            // Assume that only the default search engine can provide search suggestions.
            let engine = searchEngines.defaultEngine
            guard let suggestion = suggestions?[indexPath.row] else { return }
            if let url = engine.searchURLForQuery(suggestion) {
                Telemetry.default.recordSearch(location: .suggestion, searchEngine: engine.engineID ?? "other")
                GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.suggestion.rawValue)"].add()
                
                searchDelegate?.searchViewController(self, didSelectURL: url)
            }
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                if let url = URL(string: site.url) {
                    searchDelegate?.searchViewController(self, didSelectURL: url)
                    TelemetryWrapper.recordEvent(category: .action, method: .open, object: .bookmark, value: .awesomebarResults)
                }
            }
        case .openedTabs:
            print("Opened Tab")
            let tab = self.filteredOpenedTabs[indexPath.row]
//            tabManager.selectTab(tab)
            searchDelegate?.searchViewController(self, uuid: tab.tabUUID)
        case .remoteTabs:
            print("REMOTE TAB")
            let remoteTab = self.filteredRemoteClientTabsWrapper[indexPath.row].tab
            searchDelegate?.searchViewController(self, didSelectURL: remoteTab.URL)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        let twoLineImageOverlayCell = tableView.dequeueReusableCell(withIdentifier: "TwoLineImageOverlayCell", for: indexPath) as! TwoLineImageOverlayCell
//        if let cellOverlay = twoLineImageOverlayCell as? TwoLineImageOverlayCell {
//            cellOverlay.titleLabel.text = "HELLO"
//            return cellOverlay
//        }
//        twoLineImageOverlayCell.titleLabel.text = "HELLO"
//        return twoLineImageOverlayCell
        return getCellForSection(cell, twoLineImageOverlayCell: twoLineImageOverlayCell as! TwoLineImageOverlayCell, for: SearchListSection(rawValue: indexPath.section)!, indexPath)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            guard let count = suggestions?.count else { return 0 }
            return count < 4 ? count : 4
        case .bookmarksAndHistory:
            return data.count
        case .openedTabs:
            return filteredOpenedTabs.count
        case .remoteTabs:
            return filteredRemoteClientTabsWrapper.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return SearchListSection.allCases.count
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let section = SearchListSection(rawValue: indexPath.section) else {
            return
        }

        if section == .bookmarksAndHistory,
            let suggestion = data[indexPath.item] {
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        }
    }

    override func applyTheme() {
        super.applyTheme()

        reloadData()
    }
    
    fileprivate func getCellForSection(_ cell: UITableViewCell, twoLineImageOverlayCell: TwoLineImageOverlayCell, for section: SearchListSection, _ indexPath: IndexPath) -> UITableViewCell {
        var selectedCell = cell
        switch section {
        case .searchSuggestions:
            if let site = suggestions?[indexPath.row], let cell = cell as? TwoLineTableViewCell {
                if Locale.current.languageCode == "en" {
                    let toBold = site.replaceFirstOccurrence(of: searchQuery, with: "")
                    cell.textLabel?.attributedText = site.attributedText(boldString: toBold, font: DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel)
                    cell.detailTextLabel?.text = nil
                } else {
                    cell.setLines(site, detailText: nil)
                }
                cell.imageView?.contentMode = .center
                cell.imageView?.layer.borderWidth = 0
                cell.imageView?.image = UIImage(named: SearchViewControllerUX.SearchImage)
                cell.imageView?.tintColor = ThemeManager.instance.currentName == .dark ? UIColor.white : UIColor.black
                cell.imageView?.backgroundColor = nil
                
                let appendButton = UIButton(type: .roundedRect)
                appendButton.setImage(UIImage(named: SearchViewControllerUX.SearchAppendImage)?.withRenderingMode(.alwaysTemplate), for: .normal)
                appendButton.addTarget(self, action: #selector(append(_ :)), for: .touchUpInside)
                appendButton.tintColor = ThemeManager.instance.currentName == .dark ? UIColor.white : UIColor.black
                appendButton.sizeToFit()
                cell.accessoryView = indexPath.row > 0 ? appendButton : nil
                selectedCell = cell
            }
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                let cell = twoLineImageOverlayCell
                let isBookmark = site.bookmarked ?? false
                cell.titleLabel.text = site.title
                cell.descriptionLabel.text = site.url
                cell.leftOverlayImageView.image = isBookmark ? self.bookmarkedBadge : nil
                cell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                cell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                cell.leftImageView.contentMode = .center
                cell.leftImageView.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
                    cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
                }
                selectedCell = cell
            }
        case .openedTabs:
            if self.filteredOpenedTabs.count > indexPath.row {
                let cell = twoLineImageOverlayCell
                let openedTab = self.filteredOpenedTabs[indexPath.row]
                cell.titleLabel.text = openedTab.title
                cell.descriptionLabel.text = "Switch to tab"
                cell.leftOverlayImageView.image = switchAndSyncTabBadge
                cell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                cell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                cell.leftImageView.contentMode = .center
                cell.leftImageView.setImageAndBackground(forIcon: openedTab.displayFavicon, website: openedTab.url) { [weak cell] in
                    cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
                }
                selectedCell = cell
            }
        case .remoteTabs:
            if self.filteredRemoteClientTabsWrapper.count > indexPath.row, let cell = cell as? TwoLineTableViewCell {
                let remoteTab = self.filteredRemoteClientTabsWrapper[indexPath.row].tab
                let remoteClient = self.filteredRemoteClientTabsWrapper[indexPath.row].client
//            }
//            if let site = data[indexPath.row], let cell = cell as? TwoLineTableViewCell {
//                let isBookmark = site.bookmarked ?? false
                cell.setLines(remoteTab.title, detailText: remoteClient.name)
//                cell.setRightBadge(isBookmark ? self.bookmarkedBadge : nil)
                cell.imageView?.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                cell.imageView?.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                cell.imageView?.contentMode = .center
                cell.imageView?.image = UIImage(named: "deviceTypeMobile")
                cell.accessoryView = nil
                selectedCell = cell
//                cell.imageView?.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
//                    cell?.imageView?.image = cell?.imageView?.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
//                }
            }
        }
        return selectedCell
    }
    
    @objc func append(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPosition), let newQuery = suggestions?[indexPath.row] {
            searchDelegate?.searchViewController(self, didAppend: newQuery + " ")
            searchQuery = newQuery + " "
        }
    }
}

extension SearchViewController {
    func handleKeyCommands(sender: UIKeyCommand) {
        let initialSection = SearchListSection.bookmarksAndHistory.rawValue
        guard let current = tableView.indexPathForSelectedRow else {
            let count = tableView(tableView, numberOfRowsInSection: initialSection)
            if sender.input == UIKeyCommand.inputDownArrow, count > 0 {
                let next = IndexPath(item: 0, section: initialSection)
                self.tableView(tableView, didHighlightRowAt: next)
                tableView.selectRow(at: next, animated: false, scrollPosition: .top)
            }
            return
        }

        let nextSection: Int
        let nextItem: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyCommand.inputUpArrow:
            // we're going down, we should check if we've reached the first item in this section.
            if current.item == 0 {
                // We have, so check if we can decrement the section.
                if current.section == initialSection {
                    // We've reached the first item in the first section.
                    searchDelegate?.searchViewController(self, didHighlightText: searchQuery, search: false)
                    return
                } else {
                    nextSection = current.section - 1
                    nextItem = tableView(tableView, numberOfRowsInSection: nextSection) - 1
                }
            } else {
                nextSection = current.section
                nextItem = current.item - 1
            }
        case UIKeyCommand.inputDownArrow:
            let currentSectionItemsCount = tableView(tableView, numberOfRowsInSection: current.section)
            if current.item == currentSectionItemsCount - 1 {
                if current.section == tableView.numberOfSections - 1 {
                    // We've reached the last item in the last section
                    return
                } else {
                    // We can go to the next section.
                    nextSection = current.section + 1
                    nextItem = 0
                }
            } else {
                nextSection = current.section
                nextItem = current.item + 1
            }
        default:
            return
        }
        guard nextItem >= 0 else {
            return
        }
        let next = IndexPath(item: nextItem, section: nextSection)
        self.tableView(tableView, didHighlightRowAt: next)
        tableView.selectRow(at: next, animated: false, scrollPosition: .middle)
    }
}

/**
 * Private extension containing string operations specific to this view controller
 */
fileprivate extension String {
    func looksLikeAURL() -> Bool {
        // The assumption here is that if the user is typing in a forward slash and there are no spaces
        // involved, it's going to be a URL. If we type a space, any url would be invalid.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1192155 for additional details.
        return self.contains("/") && !self.contains(" ")
    }
}

/**
 * UIScrollView that prevents buttons from interfering with scroll.
 */
fileprivate class ButtonScrollView: UIScrollView {
    fileprivate override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
