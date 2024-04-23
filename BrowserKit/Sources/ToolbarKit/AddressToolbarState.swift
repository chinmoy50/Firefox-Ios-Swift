// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the state for the address toolbar.
public struct AddressToolbarState {
    /// VIew state for the `Location View`  in the address toolbar
    let locationViewState: LocationViewState

    /// Navigation actions of the address toolbar
    let navigationActions: [ToolbarElement]

    /// Page actions of the address toolbar
    let pageActions: [ToolbarElement]

    /// Browser actions of the address toolbar
    let browserActions: [ToolbarElement]

    /// Whether the toolbar border at the top should be displayed
    let shouldDisplayTopBorder: Bool

    /// Whether the toolbar border at the bottom should be displayed
    let shouldDisplayBottomBorder: Bool

    // We need this init as by default the init generated by the compiler for the struct will be internal and
    // can therefor not be used outside of the ToolbarKit
    public init(locationViewState: LocationViewState,
                navigationActions: [ToolbarElement],
                pageActions: [ToolbarElement],
                browserActions: [ToolbarElement],
                shouldDisplayTopBorder: Bool,
                shouldDisplayBottomBorder: Bool) {
        self.locationViewState = locationViewState
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.shouldDisplayTopBorder = shouldDisplayTopBorder
        self.shouldDisplayBottomBorder = shouldDisplayBottomBorder
    }
}
