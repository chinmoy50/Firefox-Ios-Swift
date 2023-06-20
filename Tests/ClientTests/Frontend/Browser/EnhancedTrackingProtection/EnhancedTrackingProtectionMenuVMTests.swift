// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Client

class EnhancedTrackingProtectionMenuVMTests: XCTestCase {
    func test_websiteTitle_whenURLHasBaseDomainDeliversCorrectTitle() {
        let sut = EnhancedTrackingProtectionMenuVM(
            url: URL(string: "https://firefox.com")!,
            displayTitle: "any",
            connectionSecure: true,
            globalETPIsEnabled: true,
            contentBlockerStatus: anyContentBlockerStatus())

        XCTAssertEqual(sut.websiteTitle, "firefox.com")
    }

    func test_websiteTitle_whenURLDoesNotHaveBaseDomainDeliversEmptyTitle() {
        let sut = EnhancedTrackingProtectionMenuVM(
            url: URL(string: "https://192.168.0.1:8080/path/to/resource")!,
            displayTitle: "any",
            connectionSecure: true,
            globalETPIsEnabled: true,
            contentBlockerStatus: anyContentBlockerStatus())

        XCTAssertEqual(sut.websiteTitle, "")
    }

    func test_connectionStatusString_whenConnectionIsSecureDeliversCorrectStatus() {
        let sut = EnhancedTrackingProtectionMenuVM(
            url: anyURL(),
            displayTitle: "any",
            connectionSecure: true,
            globalETPIsEnabled: true,
            contentBlockerStatus: anyContentBlockerStatus())

        XCTAssertEqual(sut.connectionStatusString, .ProtectionStatusSecure)
    }

    func test_connectionStatusString_whenConnectionIsNotSecureDeliversCorrectStatus() {
        let sut = EnhancedTrackingProtectionMenuVM(
            url: anyURL(),
            displayTitle: "any",
            connectionSecure: false,
            globalETPIsEnabled: true,
            contentBlockerStatus: anyContentBlockerStatus())

        XCTAssertEqual(sut.connectionStatusString, .ProtectionStatusNotSecure)
    }

    // MARK: Helpers

    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }

    private func anyContentBlockerStatus() -> BlockerStatus {
        .blocking
    }
}
