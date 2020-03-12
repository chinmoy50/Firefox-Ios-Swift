/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import MappaMundi
import XCTest

class L10nBaseSnapshotTests: XCTestCase {

    var app: XCUIApplication!
    var navigator: MMNavigator<FxUserState>!
    var userState: FxUserState!

    var skipIntro: Bool {
        return true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.terminate()
        var args = [LaunchArguments.ClearProfile, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet]
        if skipIntro {
            args.append(LaunchArguments.SkipIntro)
        }
        springboardStart(app, args: args)

        let map = createScreenGraph(for: self, with: app)
        navigator = map.navigator()
        userState = navigator.userState

        userState.showIntro = !skipIntro

        navigator.synchronizeWithUserState()
    }

    func springboardStart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared.press(.home)
        app.launchArguments += [LaunchArguments.Test] + args
        app.activate()
    }

    func Base.helper.waitForExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists == true")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }

    func waitForNoExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists != true")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }

    func Base.helper.loadWebPage(url: String, waitForOtherElementWithAriaLabel ariaLabel: String) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }

    func Base.helper.loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }
}
