/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import CoreSpotlight
import MobileCoreServices
import WebKit

private let browsingActivityType: String = "org.mozilla.ios.firefox.browsing"

private let searchableIndex = CSSearchableIndex(name: "firefox")

class UserActivityHandler {
    private var tabObservers: TabObservers!

    init() {
        self.tabObservers = registerFor(
                                .didLoseFocus,
                                .didGainFocus,
                                .didChangeURL,
                                .didLoadPageMetadata,
                                // .didLoadFavicon, // TODO: Bug 1390294
                                .didClose,
                                queue: .main)
    }

    deinit {
        unregister(tabObservers)
    }

    class func clearSearchIndex(completionHandler: ((Error?) -> Void)? = nil) {
        searchableIndex.deleteAllSearchableItems(completionHandler: completionHandler)
    }

    fileprivate func setUserActivityForTab(_ tab: Tab, url: URL) {
        guard let isPrivate = tab.ref?.isPrivate, !isPrivate, url.isWebPage(includeDataURIs: false), !url.isLocal else {
            tab.ref?.userActivity?.resignCurrent()
            tab.ref?.userActivity = nil
            return
        }

        tab.ref?.userActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: browsingActivityType)
        userActivity.webpageURL = url
        userActivity.becomeCurrent()

        tab.ref?.userActivity = userActivity
    }
}

extension UserActivityHandler: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
        tab.ref?.userActivity?.becomeCurrent()
    }

    func tabDidLoseFocus(_ tab: Tab) {
        tab.ref?.userActivity?.resignCurrent()
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        setUserActivityForTab(tab, url: url)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        guard let url = URL(string: metadata.siteURL) else {
            return
        }

        setUserActivityForTab(tab, url: url)
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.ref?.userActivity else {
            return
        }
        tab.ref?.userActivity = nil
        userActivity.invalidate()
    }
}
