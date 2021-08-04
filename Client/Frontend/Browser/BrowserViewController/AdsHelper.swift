/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

struct SearchProviderModel {
    typealias Predicate = (String) -> Bool
    let name: String
    let regexp: String
    let queryParam: String
    let codeParam: String
    let codePrefixes: [String]
    let followOnParams: [String]
    let extraAdServersRegexps: [String]
    let searchProviderCookie: SearchProviderCookie?
    
    func containsAds(urls: [String]) -> Bool {
        let predicates: [Predicate] = extraAdServersRegexps.map { regex in
            return { url in
                return url.range(of: regex, options: .regularExpression) != nil
            }
        }
        
        for url in urls {
            for predicate in predicates {
                guard predicate(url) else { continue }
                return true
            }
        }
        
        return false
    }
}

struct SearchProviderCookie {
    let extraCodeParam: String
    let extraCodePrefixes: [String]
    let host: String
    let name: String
    let codeParam: String
    let codePrefixes: [String]
}

class AdsHelper: TabContentScript {
    let providerList = [
        SearchProviderModel(
            name: "google",
            regexp: #"^https:\/\/www\.google\.(?:.+)\/search"#,
            queryParam: "q",
            codeParam: "client",
            codePrefixes: ["firefox"],
            followOnParams: ["oq", "ved", "ei"],
            extraAdServersRegexps: [#"^https?:\/\/www\.google(?:adservices)?\.com\/(?:pagead\/)?aclk"#],
            searchProviderCookie: nil
        ),
        SearchProviderModel(
            name: "duckduckgo",
            regexp: #"^https:\/\/duckduckgo\.com\/"#,
            queryParam: "q",
            codeParam: "t",
            codePrefixes: ["f"],
            followOnParams: [],
            extraAdServersRegexps: [
                #"^https:\/\/duckduckgo.com\/y\.js"#,
                #"^https:\/\/www\.amazon\.(?:[a-z.]{2,24}).*(?:tag=duckduckgo-)"#
            ],
            searchProviderCookie: nil
        ),
        SearchProviderModel(
            name: "yahoo",
            regexp: #"^https:\/\/(?:.*)search\.yahoo\.com\/search"#,
            queryParam: "p",
            codeParam: "",
            codePrefixes: [],
            followOnParams: [],
            extraAdServersRegexps: [],
            searchProviderCookie: nil
        ),
        SearchProviderModel(
            name: "baidu",
            regexp: #"^https:\/\/m\.baidu\.com(?:.*)\/s"#,
            queryParam: "word",
            codeParam: "from",
            codePrefixes: ["1000969a"],
            followOnParams: ["oq"],
            extraAdServersRegexps: [],
            searchProviderCookie: nil
        ),
        SearchProviderModel(
            name: "bing",
            regexp: #"^https:\/\/www\.bing\.com\/search"#,
            queryParam: "q",
            codeParam: "pc",
            codePrefixes: ["MOZ", "MZ"],
            followOnParams: ["oq"],
            extraAdServersRegexps: [
                #"^https:\/\/www\.bing\.com\/acli?c?k"#,
                #"^https:\/\/www\.bing\.com\/fd\/ls\/GLinkPingPost\.aspx.*acli?c?k"#
            ],
            searchProviderCookie: SearchProviderCookie(
                extraCodeParam: "form",
                extraCodePrefixes: ["QBRE"],
                host: "www.bing.com",
                name: "SRCHS",
                codeParam: "PC",
                codePrefixes: ["MOZ", "MZ"]
            )
        ),
    ]
    
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "Ads"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "adsMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard
            let provider = getProviderForMessage(message: message),
            let body = message.body as? [String : Any],
            let urls = body["urls"] as? [String] else { return }
        
        print("CONSOLELOG", provider.containsAds(urls: urls))
    }
    
    private func getProviderForMessage(message: WKScriptMessage) -> SearchProviderModel? {
        guard let body = message.body as? [String : Any], let url = body["url"] as? String else { return nil }
        for provider in providerList {
            guard url.range(of: provider.regexp, options: .regularExpression) != nil else { continue }
            return provider
        }
        
        return nil
    }
}
