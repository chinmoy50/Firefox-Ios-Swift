// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the state for the address toolbar.
public struct AddressToolbarState {
    /// URL displayed in the address toolbar
    let url: URL?

    /// Navigation actions of the address toolbar
    let navigationActions: [ToolbarElement]

    /// Page actions of the address toolbar
    let pageActions: [ToolbarElement]

    /// Browser actions of the address toolbar
    let browserActions: [ToolbarElement]

    // We need this init as by default the init generated by the compiler for the struct will be internal and
    // can therefor not be used outside of the ToolbarKit
    public init(url: URL?,
                navigationActions: [ToolbarElement],
                pageActions: [ToolbarElement],
                browserActions: [ToolbarElement]) {
        self.url = url
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
    }
}
