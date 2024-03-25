// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The `ThemeManager` will be responsible for providing the theme throughout the app
public final class DefaultThemeManager: ThemeManager, Notifiable {
    // These have been carried over from the legacy system to maintain backwards compatibility
    enum ThemeKeys {
        static let themeName = "prefKeyThemeName"
        static let systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"

        enum AutomaticBrightness {
            static let isOn = "prefKeyAutomaticSwitchOnOff"
            static let thresholdValue = "prefKeyAutomaticSliderValue"
        }

        enum NightMode {
            static let isOn = "profile.NightModeStatus"
        }

        enum PrivateMode {
            // TODO: [8313] Need to consider "migration", how this will work for users will older key present but not this one
            static let isOn = "profile.PrivateModeWindowStatus"
        }
    }

    // MARK: - Variables

    private var windowThemeState: [UUID: Theme] = [:] //LightTheme()
    private var windows: [UUID: UIWindow?] = [:]
    private var allWindowUUIDs: [UUID] { return Array(windows.keys) }
    public var notificationCenter: NotificationProtocol

    private var userDefaults: UserDefaultsInterface
    private var mainQueue: DispatchQueueInterface
    private var sharedContainerIdentifier: String

    private var nightModeIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.NightMode.isOn)
    }

    private func privateModeIsOn(for window: UUID) -> Bool {
        return userDefaults.bool(forKey: ThemeKeys.PrivateMode.isOn)
    }

    public var systemThemeIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.systemThemeIsOn)
    }

    public var automaticBrightnessIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn)
    }

    public var automaticBrightnessValue: Float {
        return userDefaults.float(forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
    }

    // MARK: - Initializers

    public init(
        defaultWindowID: UUID,
        userDefaults: UserDefaultsInterface = UserDefaults.standard,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        mainQueue: DispatchQueueInterface = DispatchQueue.main,
        sharedContainerIdentifier: String
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.mainQueue = mainQueue
        self.sharedContainerIdentifier = sharedContainerIdentifier

        self.userDefaults.register(defaults: [
            ThemeKeys.systemThemeIsOn: true,
            ThemeKeys.NightMode.isOn: false,
            ThemeKeys.PrivateMode.isOn: false,
        ])

        // TODO: [8313] Can we get rid of this? This won't work unless we inject the default window etc.
        updateSavedTheme(to: getNormalSavedTheme())
        updateCurrentTheme(to: fetchSavedThemeType(for: defaultWindowID), for: defaultWindowID)

        setupNotifications(forObserver: self,
                           observing: [UIScreen.brightnessDidChangeNotification,
                                       UIApplication.didBecomeActiveNotification])
    }

    // MARK: - ThemeManager

    public func setWindow(_ window: UIWindow, for uuid: UUID) {
        windows[uuid] = window
    }

    public func currentTheme(for window: UUID?) -> Theme {
        // TODO: [8313] Need to revisit how we handle nil here, return theme for 'main'/active window
        guard let window else { return DarkTheme() }

        return windowThemeState[window] ?? DarkTheme()
    }

    public func changeCurrentTheme(_ newTheme: ThemeType, for window: UUID) {
        guard currentTheme(for: window).type != newTheme else { return }

        updateSavedTheme(to: newTheme)
        updateCurrentTheme(to: fetchSavedThemeType(for: window), for: window)
    }

    public func reloadTheme(for window: UUID) {
        updateCurrentTheme(to: fetchSavedThemeType(for: window), for: window)
    }

    public func systemThemeChanged() {
        allWindowUUIDs.forEach { uuid in
            // Ignore if:
            // the system theme is off
            // OR night mode is on
            // OR private mode is on
            guard systemThemeIsOn,
                  !nightModeIsOn,
                  !privateModeIsOn(for: uuid)
            else { return }

            changeCurrentTheme(getSystemThemeType(), for: uuid)
        }
    }

    public func setSystemTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.systemThemeIsOn)

        if isOn {
            systemThemeChanged()
        } else if automaticBrightnessIsOn {
            updateThemeBasedOnBrightness()
        }
    }

    public func setPrivateTheme(isOn: Bool, for window: UUID) {
        guard userDefaults.bool(forKey: ThemeKeys.PrivateMode.isOn) != isOn else { return }

        userDefaults.set(isOn, forKey: ThemeKeys.PrivateMode.isOn)

        updateCurrentTheme(to: fetchSavedThemeType(for: window), for: window)
    }

    public func setAutomaticBrightness(isOn: Bool) {
        guard automaticBrightnessIsOn != isOn else { return }

        userDefaults.set(isOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        brightnessChanged()
    }

    public func setAutomaticBrightnessValue(_ value: Float) {
        userDefaults.set(value, forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
        brightnessChanged()
    }

    public func brightnessChanged() {
        if automaticBrightnessIsOn {
            updateThemeBasedOnBrightness()
        }
    }

    public func getNormalSavedTheme() -> ThemeType {
        if let savedThemeDescription = userDefaults.string(forKey: ThemeKeys.themeName),
           let savedTheme = ThemeType(rawValue: savedThemeDescription) {
            return savedTheme
        }

        return getSystemThemeType()
    }

    // MARK: - Private methods

    private func updateSavedTheme(to newTheme: ThemeType) {
        // We never want to save the private theme because it's meant to override
        // whatever current theme is set. This means that we need to know the theme
        // before we went into private mode, in order to be able to return to it.
        guard newTheme != .privateMode else { return }
        userDefaults.set(newTheme.rawValue, forKey: ThemeKeys.themeName)
    }

    private func updateCurrentTheme(to newTheme: ThemeType, for window: UUID) {
        windowThemeState[window] = newThemeForType(newTheme)

        // Overwrite the user interface style on the window attached to our scene
        // once we have multiple scenes we need to update all of them

        // TODO: [8313] Fix for multi-window
        windows.forEach { (uuid, window) in
            window?.overrideUserInterfaceStyle = currentTheme(for: uuid).type.getInterfaceStyle()
        }

        mainQueue.ensureMainThread { [weak self] in
            self?.notificationCenter.post(name: .ThemeDidChange)
        }
    }

    private func fetchSavedThemeType(for window: UUID) -> ThemeType {
        if privateModeIsOn(for: window) { return .privateMode }
        if nightModeIsOn { return .dark }

        return getNormalSavedTheme()
    }

    private func getSystemThemeType() -> ThemeType {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? ThemeType.dark : ThemeType.light
    }

    private func newThemeForType(_ type: ThemeType) -> Theme {
        switch type {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .privateMode:
            return PrivateModeTheme()
        }
    }

    private func updateThemeBasedOnBrightness() {
        // TODO: [8313] Revisit / fix.
        allWindowUUIDs.forEach { uuid in
            let currentValue = Float(UIScreen.main.brightness)

            if currentValue < automaticBrightnessValue {
                changeCurrentTheme(.dark, for: uuid)
            } else {
                changeCurrentTheme(.light, for: uuid)
            }
        }
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScreen.brightnessDidChangeNotification:
            brightnessChanged()
        case UIApplication.didBecomeActiveNotification:
            self.systemThemeChanged()
        default:
            return
        }
    }
}
