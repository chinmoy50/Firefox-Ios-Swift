// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperURLType {
    case metadata
    case imageURL
}

struct WallpaperURLProvider {
    // MARK: - Properties
    enum URLProviderError: Error {
        case noBundledURL
        case invalidURL
    }

    enum WallpaperMetadataEndpoint: String {
        case v1
    }

    private let wallpaperURLScheme = "MozWallpaperURLScheme"
    static let testURL = "https://my.test.url"
    let currentMetadataEndpoint: WallpaperMetadataEndpoint = .v1

    func url(
        for urlType: WallpaperURLType,
        withKey key: String = "",
        andFileName fileName: String = ""
    ) throws -> URL {
        switch urlType {
        case .metadata: return try metadataURL()
        case .imageURL: return try imageURLWith(key, and: fileName)
        }
    }

    private func metadataURL() throws -> URL {
        let scheme = try urlScheme()
        guard let url = URL(string: "\(scheme)/metadata/\(currentMetadataEndpoint.rawValue)/wallpapers.json") else {
            throw URLProviderError.invalidURL
        }

        return url
    }

    private func imageURLWith(_ key: String, and fileName: String) throws -> URL {
        let scheme = try urlScheme()
        guard let url = URL(string: "\(scheme)/ios/\(key)/\(fileName).png") else {
            throw URLProviderError.invalidURL
        }

        return url
    }

    /// Builds a URL for the server based on the specified environment.
    private func urlScheme() throws -> String {
        if AppConstants.isRunningTest { return WallpaperURLProvider.testURL }
        // roux - add this to the url
        return "https://assets.mozilla.net/mobile-wallpapers"

        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else { throw URLProviderError.noBundledURL }

        return appToken
    }
}
