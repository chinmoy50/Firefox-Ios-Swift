// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

enum AppScreenState: Equatable {
    case onboardingViewController(OnboardingViewControllerState)
    case browserViewController(BrowserViewControllerState)
    case remoteTabsPanel(RemoteTabsPanelState)
    case tabsPanel(TabsPanelState)
    case tabsTray(TabTrayState)
    case themeSettings(ThemeSettingsState)
    case tabPeek(TabPeekState)
    case microsurvey(MicrosurveyState)

    static let reducer: Reducer<Self> = { state, action in
        switch state {
        case .onboardingViewController(let state):
            return .onboardingViewController(OnboardingViewControllerState.reducer(state, action))
        case .tabPeek(let state):
            return .tabPeek(TabPeekState.reducer(state, action))
        case .themeSettings(let state):
            return .themeSettings(ThemeSettingsState.reducer(state, action))
        case .tabsTray(let state):
            return .tabsTray(TabTrayState.reducer(state, action))
        case .tabsPanel(let state):
            return .tabsPanel(TabsPanelState.reducer(state, action))
        case .remoteTabsPanel(let state):
            return .remoteTabsPanel(RemoteTabsPanelState.reducer(state, action))
        case .browserViewController(let state):
            return .browserViewController(BrowserViewControllerState.reducer(state, action))
        case .microsurvey(let state):
            return .microsurvey(MicrosurveyState.reducer(state, action))
        }
    }

    /// Returns the matching AppScreen enum for a given AppScreenState
    var associatedAppScreen: AppScreen {
        switch self {
        case .browserViewController: return .browserViewController
        case .onboardingViewController: return .onboardingViewController
        case .themeSettings: return .themeSettings
        case .tabsTray: return .tabsTray
        case .tabsPanel: return .tabsPanel
        case .remoteTabsPanel: return .remoteTabsPanel
        case .tabPeek: return .tabPeek
        case .microsurvey: return .microsurvey
        }
    }

    var windowUUID: WindowUUID? {
        switch self {
        case .browserViewController(let state): return state.windowUUID
        case .onboardingViewController(let state): return state.windowUUID
        case .remoteTabsPanel(let state): return state.windowUUID
        case .tabsTray(let state): return state.windowUUID
        case .tabsPanel(let state): return state.windowUUID
        case .themeSettings(let state): return state.windowUUID
        case .tabPeek(let state): return state.windowUUID
        case .microsurvey(let state): return state.windowUUID
        }
    }
}

struct ActiveScreensState: Equatable {
    let screens: [AppScreenState]

    init() {
        self.screens = []
    }

    init(screens: [AppScreenState]) {
        self.screens = screens
    }

    static let reducer: Reducer<Self> = { state, action in
        // Add or remove screens from the active screen list as needed
        var screens = updateActiveScreens(action: action, screens: state.screens)

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }

    private static func updateActiveScreens(action: Action, screens: [AppScreenState]) -> [AppScreenState] {
        guard let action = action as? ScreenAction else { return screens }

        var screens = screens

        switch action.actionType {
        case ScreenActionType.closeScreen:
            screens = screens.filter({
                return $0.associatedAppScreen != action.screen || $0.windowUUID != action.windowUUID
            })
        case ScreenActionType.showScreen:
            let uuid = action.windowUUID
            switch action.screen {
            case .browserViewController:
                screens.append(.browserViewController(BrowserViewControllerState(windowUUID: uuid)))
            case .onboardingViewController:
                screens.append(.onboardingViewController(OnboardingViewControllerState(windowUUID: uuid)))
            case .remoteTabsPanel:
                screens.append(.remoteTabsPanel(RemoteTabsPanelState(windowUUID: uuid)))
            case .tabsTray:
                screens.append(.tabsTray(TabTrayState(windowUUID: uuid)))
            case .tabsPanel:
                screens.append(.tabsPanel(TabsPanelState(windowUUID: uuid)))
            case .themeSettings:
                screens.append(.themeSettings(ThemeSettingsState(windowUUID: uuid)))
            case .tabPeek:
                screens.append(.tabPeek(TabPeekState(windowUUID: uuid)))
            case .microsurvey:
                screens.append(.microsurvey(MicrosurveyState(windowUUID: uuid)))
            }
        default:
            return screens
        }

        return screens
    }
}
