//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

typealias ContileResult = Swift.Result<[Contile], Error>

protocol ContileProviderInterface {
    /// Fetch contiles either from cache or backend
    /// - Parameter completion: Returns an array of Contile, can be empty
    func fetchContiles(completion: @escaping (ContileResult) -> Void)
}

/// `Contile` is short for contextual tiles. This provider returns data that is used in Shortcuts (Top Sites) section on the Firefox home page.
class ContileProvider: ContileProviderInterface, Loggable {

    private let contileResourceEndpoint = "https://contile.services.mozilla.com/v1/tiles"

    lazy var urlSession = makeURLSession(userAgent: UserAgent.mobileUserAgent(),
                                         configuration: URLSessionConfiguration.default)

    enum Error: Swift.Error {
        case failure
    }

    func fetchContiles(completion: @escaping (ContileResult) -> Void) {
        guard let resourceEndpoint = URL(string: contileResourceEndpoint) else {
            browserLog.error("The Contile resource URL is invalid: \(contileResourceEndpoint)")
            completion(.failure(Error.failure))
            return
        }

        let request = URLRequest(url: resourceEndpoint,
                                 cachePolicy: .reloadIgnoringCacheData,
                                 timeoutInterval: 5)

        if let cachedData = findCachedData(for: request) {
            decode(data: cachedData, completion: completion)
        } else {
            fetchContiles(request: request, completion: completion)
        }
    }

    private func fetchContiles(request: URLRequest, completion: @escaping (ContileResult) -> Void) {
        let fetchTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.browserLog.debug("An error occurred while fetching data: \(error)")
                completion(Result.failure(Error.failure))
                return
            }

            guard let response = validatedHTTPResponse(response, statusCode: 200..<300), let data = data else {
                completion(.failure(Error.failure))
                return
            }

            self.cache(response: response, for: request, with: data)
            self.decode(data: data, completion: completion)
        }

        fetchTask.resume()
    }

    private func decode(data: Data, completion: @escaping (ContileResult) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let rootNote = try decoder.decode(Contiles.self, from: data)
            var contiles = rootNote.tiles
            contiles.sort { $0.position ?? 0 < $1.position ?? 0 }
            completion(.success(contiles))

        } catch let error {
            self.browserLog.error("Unable to parse with error: \(error)")
            completion(.failure(Error.failure))
        }
    }

    // MARK: Caching
    // TODO: Laurie - Protocol for both pocket and contile ?

    // The maximum contile cache age, 1 hour in milliseconds
    private let maxCacheAge: Timestamp = OneMinuteInMilliseconds * 60
    private let cacheAgeKey = "cache-time"

    private func findCachedData(for request: URLRequest) -> Data? {
        let cachedResponse = URLCache.shared.cachedResponse(for: request)
        guard let cachedAtTime = cachedResponse?.userInfo?[cacheAgeKey] as? Timestamp,
              (Date.now() - cachedAtTime) < maxCacheAge,
              let data = cachedResponse?.data else {
            return nil
        }

        return data
    }

    private func cache(response: HTTPURLResponse?, for request: URLRequest, with data: Data?) {
        guard let response = response, let data  = data else {
            return
        }

        let metadata = [cacheAgeKey: Date.now()]
        let cachedResp = CachedURLResponse(response: response, data: data, userInfo: metadata, storagePolicy: .allowed)
        URLCache.shared.removeCachedResponse(for: request)
        URLCache.shared.storeCachedResponse(cachedResp, for: request)
    }
}
