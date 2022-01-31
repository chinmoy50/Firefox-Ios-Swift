// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Shared
import Storage
import UIKit
import WebKit

import XCTest

class TabManagerStoreTests: XCTestCase {

    func testNoData() {
        let manager = createManager()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
    }

    func testAddTabWithoutStoring_hasNoData() {
        let manager = createManager()
        let configuration = createConfiguration()
        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2, isPrivate: true)
        XCTAssertEqual(manager.tabs.count, 2)
        XCTAssertEqual(manager.testTabCountOnDisk(), 0)
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
    }

    func testPrivateTabsAreArchived() {
        let manager = createManager()
        let configuration = createConfiguration()
        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2, isPrivate: true)
        XCTAssertEqual(manager.tabs.count, 2)

        waitStoreChanges(manager: manager, expectedTabCount: 2)
    }

    func testNormalTabsAreArchived_storeMultipleTimesProperly() {
        let manager = createManager()
        let configuration = createConfiguration()
        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
        XCTAssertEqual(manager.tabs.count, 2)

        waitStoreChanges(manager: manager, expectedTabCount: 2)

        // Add 2 more tabs
        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
        XCTAssertEqual(manager.tabs.count, 4)

        waitStoreChanges(manager: manager, expectedTabCount: 4)
    }

    func testRemoveAndAddTab_doesntStoreRemovedTabs() {
        let manager = createManager()
        let configuration = createConfiguration()
        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
        XCTAssertEqual(manager.tabs.count, 2)

        // Remove all tabs, and add just 1 tab
        manager.removeAll()
        addTabWithSessionData(manager: manager, configuration: configuration)

        waitStoreChanges(manager: manager, expectedTabCount: 1)
    }
}

// MARK: - Helper methods
private extension TabManagerStoreTests {

    func createManager(file: StaticString = #file, line: UInt = #line) -> TabManager {
        let profile = TabManagerMockProfile()
        let manager = TabManager(profile: profile, imageStore: nil)
        manager.testClearArchive()

        trackForMemoryLeaks(manager, file: file, line: line)
        trackForMemoryLeaks(profile, file: file, line: line)

        return manager
    }

    func createConfiguration(file: StaticString = #file, line: UInt = #line) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configureiPad()

        trackForMemoryLeaks(configuration, file: file, line: line)
        return configuration
    }

    func configureiPad() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        // BVC.viewWillAppear() calls restoreTabs() which interferes with these tests.
        // (On iPhone, ClientTests never dismiss the intro screen, on iPad the intro is a popover on the BVC).
        // Wait for this to happen (UIView.window only gets assigned after viewWillAppear()), then begin testing.
        let bvc = (UIApplication.shared.delegate as! AppDelegate).browserViewController
        let predicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: "view.window != nil"), object: bvc)
        wait(for: [predicate], timeout: 20)
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }

    func addNumberOfTabs(manager: TabManager, configuration: WKWebViewConfiguration, tabNumber: Int, isPrivate: Bool = false) {
        for _ in 0..<tabNumber {
            addTabWithSessionData(manager: manager, configuration: configuration, isPrivate: isPrivate)
        }
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTabWithSessionData(manager: TabManager, configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        let tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com")!
        manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
    }

    func waitStoreChanges(manager: TabManager, expectedTabCount: Int, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Saved store changes")
        manager.storeChanges(writeCompletion: { [weak manager] in
            guard let manager = manager else { XCTFail("Manager shouldn't be nil"); return }
            XCTAssertEqual(manager.testTabCountOnDisk(), expectedTabCount, file: file, line: line)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 20, handler: nil)
    }
}
