// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

/// Used to setup bookmarks and folder cell in Bookmarks panel, getting their viewModel
protocol BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel

    func didSelect(profile: Profile,
                   windowUUID: WindowUUID,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?,
                   logger: Logger)
}

extension BookmarkFolderData: BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel {
        var title: String
        if isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            title = localizedString
        } else {
            title = self.title
        }

        return OneLineTableViewCellViewModel(title: title,
                                             leftImageView: leftImageView,
                                             accessoryView: nil,
                                             accessoryType: .disclosureIndicator)
    }

    func didSelect(profile: Profile,
                   windowUUID: WindowUUID,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?,
                   logger: Logger) {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarkHandler: profile.places,
                                                bookmarkFolderGUID: guid)
        let nextController = BookmarksPanel(viewModel: viewModel, windowUUID: windowUUID)
        if isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            nextController.title = localizedString
        } else {
            nextController.title = title
        }
        nextController.libraryPanelDelegate = libraryPanelDelegate
        navigationController?.pushViewController(nextController, animated: true)
    }
}

extension BookmarkItemData: BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel {
        var title: String
        if self.title.isEmpty {
            title = url
        } else {
            title = self.title
        }

        return OneLineTableViewCellViewModel(title: title,
                                             leftImageView: nil,
                                             accessoryView: nil,
                                             accessoryType: .disclosureIndicator)
    }

    func didSelect(profile: Profile,
                   windowUUID: WindowUUID,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?,
                   logger: Logger) {
        // If we can't get a real URL out of what should be a URL, we let the user's
        // default search engine give it a shot.
        // Typically we'll be in this state if the user has tapped a bookmarked search template
        // (e.g., "http://foo.com/bar/?query=%s"), and this will get them the same behavior as if
        // they'd copied and pasted into the URL bar.
        // See BrowserViewController.urlBar:didSubmitText:.
        guard let url = URIFixup.getURL(url) ?? profile.searchEngines.defaultEngine?.searchURLForQuery(url) else {
            logger.log("Invalid URL, and couldn't generate a search URL for it.",
                       level: .warning,
                       category: .library)
            return
        }
        libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .bookmark)
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .bookmark, value: .bookmarksPanel)
    }
}

// MARK: FxBookmarkNode viewModel helper
extension FxBookmarkNode {
    var leftImageView: UIImage? {
        return UIImage(named: StandardImageIdentifiers.Large.folder)?.withRenderingMode(.alwaysTemplate)
    }

    var chevronImage: UIImage? {
        return UIImage(named: StandardImageIdentifiers.Large.chevronRight)?.withRenderingMode(.alwaysTemplate)
    }
}
