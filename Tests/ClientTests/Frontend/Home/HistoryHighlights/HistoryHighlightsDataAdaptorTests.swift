// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import MozillaAppServices

class HistoryHighlightsDataAdaptorTests: XCTestCase {

    var subject: RecentlyVisitedDataAdaptor!
    var historyManager: MockRecentlyVisitedManager!
    var notificationCenter: MockNotificationCenter!
    var delegate: MockHistoryHighlightsDelegate!
    var deletionUtility: MockHistoryDeletionProtocol!

    override func setUp() {
        super.setUp()

        historyManager = MockRecentlyVisitedManager()
        notificationCenter = MockNotificationCenter()
        delegate = MockHistoryHighlightsDelegate()
        deletionUtility = MockHistoryDeletionProtocol()

        let subject = RecentlyVisitedDataAdaptorImplementation(
            historyManager: historyManager,
            profile: MockProfile(),
            tabManager: MockTabManager(),
            notificationCenter: notificationCenter,
            deletionUtility: deletionUtility)
        subject.delegate = delegate
        notificationCenter.notifiableListener = subject
        self.subject = subject
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        historyManager = nil
        notificationCenter = nil
        delegate = nil
        deletionUtility = nil
    }

    // Loads history on first launch with data
    func testInitialLoadWithHistoryData() {
        let item: RecentlyVisitedItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item])

        let results = subject.getRecentlyVisited()

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(historyManager.getDataCallCount, 1)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 1)
    }

    // Loads history on first launch without data
    func testInitialLoadWithNoHistoryData() {
        historyManager.callGetHighlightsDataCompletion(result: [])

        let results = subject.getRecentlyVisited()

        XCTAssert(results.isEmpty)
        XCTAssertEqual(historyManager.getDataCallCount, 1)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 1)
    }

    // Reloads for notification
    func testReloadDataOnNotification() {
        historyManager.callGetHighlightsDataCompletion(result: [])

        notificationCenter.post(name: .HistoryUpdated)

        let item1: RecentlyVisitedItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        let item2: RecentlyVisitedItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item1, item2])

        let results = subject.getRecentlyVisited()

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(historyManager.getDataCallCount, 2)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 2)
    }

    func testDeleteIndividualItem() {
        let item1: RecentlyVisitedItem = HistoryHighlight(score: 0,
                                                    placeId: 0,
                                                    url: "www.firefox.com",
                                                    title: "",
                                                    previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item1])

        subject.delete(item1)
        deletionUtility.callDeleteCompletion(result: true)

        XCTAssertEqual(historyManager.getDataCallCount, 2)
    }

    func testDeleteGroupItem() {
        let item: RecentlyVisitedItem = HistoryHighlight(score: 0,
                                                    placeId: 0,
                                                    url: "www.firefox.com",
                                                    title: "",
                                                    previewImageUrl: "")

        let group: RecentlyVisitedItem = ASGroup(searchTerm: "foxes",
                                           groupedItems: [item],
                                           timestamp: 0)

        historyManager.callGetHighlightsDataCompletion(result: [group])

        subject.delete(group)
        deletionUtility.callDeleteCompletion(result: true)

        XCTAssertEqual(historyManager.getDataCallCount, 2)
    }
}
