// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    // Current theme
    func currentTheme(for window: WindowUUID?) -> Theme

    // System theme and brightness settings
    var systemThemeIsOn: Bool { get }
    var automaticBrightnessIsOn: Bool { get }
    var automaticBrightnessValue: Float { get }
    func systemThemeChanged()
    func setSystemTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)
    func updateThemeBasedOnBrightess()
    func getUserManualTheme() -> ThemeType

    // Window management and window-specific themeing
    func changeCurrentTheme(_ newTheme: ThemeType, for window: WindowUUID)
    func setPrivateTheme(isOn: Bool, for window: WindowUUID)
    func getPrivateThemeIsOn(for window: WindowUUID) -> Bool
    func reloadTheme(for window: WindowUUID)
    func setWindow(_ window: UIWindow, for uuid: WindowUUID)
    func windowDidClose(uuid: WindowUUID)

    // Theme functions for app extensions

    /// Returns the general theme setting outside of any specific iOS window.
    /// This is generally only meant to be used in scenarios where the UI is
    /// presented outside the context of any particular browser window, such
    /// as in our app extensions.
    func windowNonspecificTheme() -> Theme
}
