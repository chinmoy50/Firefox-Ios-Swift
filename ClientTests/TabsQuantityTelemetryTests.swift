// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TabsQuantityTelemetryTests: XCTestCase {

    func testTrackTabsQuantity_withNormalTab_gleanIsCalled() {
        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        tabManager.addTab()

        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity, expectedValue: 0)
        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity, expectedValue: 1)
    }

    func testTrackTabsQuantity_withPrivateTab_gleanIsCalled() {
        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        tabManager.addTab(isPrivate: true)

        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity, expectedValue: 1)
        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity, expectedValue: 0)
    }
}
