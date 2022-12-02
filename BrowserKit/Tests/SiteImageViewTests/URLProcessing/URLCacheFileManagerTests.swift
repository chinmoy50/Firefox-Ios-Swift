// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

class URLCacheFileManagerTests: XCTestCase {

    var subject: DefaultURLCacheFileManager!
    var mockFileManager: MockFileManager!

    override func setUp() {
        mockFileManager = MockFileManager()
        subject = DefaultURLCacheFileManager(fileManager: mockFileManager)
    }

    override func tearDown() {
        mockFileManager = nil
        subject = nil
    }

    func testGetURLCache() async {
        _ = await subject.getURLCache()
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 1)
        XCTAssertEqual(mockFileManager.urlsCalledCount, 2)
    }

    func testSaveURLCache() async {
        await subject.saveURLCache(data: Data())
        XCTAssertEqual(mockFileManager.urlsCalledCount, 1)
    }
}

class MockFileManager: FileManagerProtocol {

    var urls = [URL(string: "firefox")!]
    var fileExists = true
    var fileExistsCalledCount = 0
    var urlsCalledCount = 0

    func fileExists(atPath path: String) -> Bool {
        fileExistsCalledCount += 1
        return fileExists
    }

    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsCalledCount += 1
        return urls
    }
}
