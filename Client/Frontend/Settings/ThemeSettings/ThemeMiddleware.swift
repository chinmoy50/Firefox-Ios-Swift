// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState() -> ThemeSettingsState
    func toggleUseSystemAppearance(_ enabled: Bool)
    func toggleAutomaticBrightness(_ enabled: Bool)
    func updateManualTheme(_ theme: ThemeType)
    func updateUserBrightness(_ value: Float)
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = { state, action in
        switch action {
        case ThemeSettingsAction.themeSettingsDidAppear:
            let currentThemeState = self.getCurrentThemeManagerState()
            store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(currentThemeState))
        case ThemeSettingsAction.toggleUseSystemAppearance(let enabled):
            self.toggleUseSystemAppearance(enabled)
            store.dispatch(ThemeSettingsAction.systemThemeChanged(self.legacyThemeManager.systemThemeIsOn))
        case ThemeSettingsAction.enableAutomaticBrightness(let enabled):
            self.toggleAutomaticBrightness(enabled)
<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
            store.dispatch(ThemeSettingsAction.automaticBrightnessChanged(self.legacyThemeManager.automaticBrightnessIsOn))
=======
            store.dispatch(
                ThemeSettingsAction.automaticBrightnessChanged(self.themeManager.automaticBrightnessIsOn)
            )
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
        case ThemeSettingsAction.switchManualTheme(let theme):
            self.updateManualTheme(theme)
            store.dispatch(ThemeSettingsAction.manualThemeChanged(theme))
        case ThemeSettingsAction.updateUserBrightness(let value):
            self.updateUserBrightness(value)
            store.dispatch(ThemeSettingsAction.userBrightnessChanged(value))
        case ThemeSettingsAction.receivedSystemBrightnessChange:
            self.updateThemeBasedOnSystemBrightness()
            let systemBrightness = self.getScreenBrightness()
            store.dispatch(ThemeSettingsAction.systemBrightnessChanged(systemBrightness))
        case PrivateModeMiddlewareAction.privateModeUpdated(let newState):
            self.toggleUsePrivateTheme(to: newState)
        default:
            break
        }
    }

    // MARK: - Helper func
<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
    func getCurrentThemeManagerState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: legacyThemeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: legacyThemeManager.automaticBrightnessIsOn,
=======
    func getCurrentThemeManagerState(windowUUID: WindowUUID?) -> ThemeSettingsState {
        // TODO: [8188] Revisit UUID handling, needs additional investigation.
        ThemeSettingsState(windowUUID: windowUUID ?? WindowUUID.unavailable,
                           useSystemAppearance: themeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: themeManager.automaticBrightnessIsOn,
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
                           manualThemeSelected: themeManager.currentTheme.type,
                           userBrightnessThreshold: themeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        legacyThemeManager.systemThemeIsOn = enabled
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleUsePrivateTheme(to state: Bool) {
        themeManager.setPrivateTheme(isOn: state)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
    func updateManualTheme(_ theme: ThemeType) {
        let isLightTheme = theme == .light
        legacyThemeManager.current = isLightTheme ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(isLightTheme ? .light : .dark)
=======
    func updateManualTheme(_ newTheme: ThemeType) {
        themeManager.changeCurrentTheme(newTheme)
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeMiddleware.swift
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
    }

    func updateThemeBasedOnSystemBrightness() {
        themeManager.brightnessChanged()
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }
}
