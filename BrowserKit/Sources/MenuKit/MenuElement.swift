// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct MenuElement: Equatable {
    let title: String
    let iconName: String
    let isEnabled: Bool
    let isActive: Bool
    let a11yLabel: String
    let a11yHint: String?
    let a11yId: String

    let action: (() -> Void)?

    // We need this init as by default the init generated by the compiler
    // for the struct will be internal and can not be used outside of MenuKit
    public init(
        title: String,
        iconName: String,
        isEnabled: Bool,
        isActive: Bool,
        a11yLabel: String,
        a11yHint: String?,
        a11yId: String,
        action: (() -> Void)?
    ) {
        self.title = title
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.a11yLabel = a11yLabel
        self.a11yHint = a11yHint
        self.a11yId = a11yId
        self.action = action
    }

    public static func == (lhs: MenuElement, rhs: MenuElement) -> Bool {
        return lhs.title == rhs.title &&
        lhs.iconName == rhs.iconName &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.isActive == rhs.isActive &&
        lhs.a11yLabel == rhs.a11yLabel &&
        lhs.a11yHint == rhs.a11yHint &&
        lhs.a11yId == rhs.a11yId
    }

}
