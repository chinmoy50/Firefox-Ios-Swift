// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Fuzi

protocol ImageURLFetcher {
    func fetchFaviconURL(siteURL: URL, completion: @escaping ((Result<URL, URLError>) -> ()))
}

class DefaultImageURLFetcher: ImageURLFetcher {

    enum RequestConstants {
        static let timeout: TimeInterval = 5
        static let userAgent = ""
    }

    func fetchFaviconURL(siteURL: URL, completion: @escaping ((Result<URL, URLError>) -> ())) {
        fetchDataForURL(siteURL) { [weak self] result in
            switch result {
            case let .success(data):
                self?.processHTMLDocument(siteURL: siteURL,
                                          data: data,
                                          completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }   
        }
    }

    private func fetchDataForURL(_ url: URL, completion: @escaping ((Result<Data, URLError>) -> ())) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": RequestConstants.userAgent]
        configuration.timeoutIntervalForRequest = RequestConstants.timeout

        let urlSession = URLSession(configuration: configuration)

        urlSession.dataTask(with: url) { data, _, error in
            guard let data = data else {
                completion(.failure(.invalidHTML))
                return
            }
            completion(.success(data))
        }.resume()
    }

    private func processHTMLDocument(siteURL: URL, data: Data, completion: @escaping ((Result<URL, URLError>) -> ())) {
        guard let root = try? HTMLDocument(data: data) else {
            completion(.failure(.invalidHTML))
            return
        }

        var reloadURL: URL?

        // Check if we need to redirect
        for meta in root.xpath("//head/meta") {
            if let refresh = meta["http-equiv"], refresh == "Refresh",
                let content = meta["content"],
                let index = content.range(of: "URL="),
                let url = URL(string: String(content[index.upperBound...])) {
                reloadURL = url
            }
        }

        if let reloadURL = reloadURL {
            fetchFaviconURL(siteURL: reloadURL, completion: completion)
            return
        }

        // Search for the first reference to an icon
        for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
            guard let href = link["href"] else {
                continue
            }

            if let faviconURL = URL(string: href, relativeTo: siteURL) {
                completion(.success(faviconURL))
                return
            }
        }

        // Fallback to the favicon at the root of the domain
        // This is a fall back because it's generally low res
        if let faviconURL = URL(string: "/favicon.ico", relativeTo: siteURL) {
            completion(.success(faviconURL))
        }

        completion(.failure(.noFaviconFound))
        return
    }
}
