/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

class SavedTab: NSObject, NSCoding {
    var isSelected: Bool = false
    var title: String? = nil
    var url: URL? = nil
    var isPrivate: Bool = false
    var sessionData: SessionData? = nil
    var screenshotUUID: UUID? = nil
    var faviconURL: String? = nil
    
    var jsonDictionary: [String: AnyObject] {
        let title: String = self.title ?? "null"
        let faviconURL: String = self.faviconURL ?? "null"
        let uuid: String = self.screenshotUUID?.uuidString ?? "null"
        
        var json: [String: AnyObject] = [
            "title": title as AnyObject,
            "isPrivate": String(self.isPrivate) as AnyObject,
            "isSelected": String(self.isSelected) as AnyObject,
            "faviconURL": faviconURL as AnyObject,
            "screenshotUUID": uuid as AnyObject,
            "url": url as AnyObject
        ]
        
        if let sessionDataInfo = self.sessionData?.jsonDictionary {
            json["sessionData"] = sessionDataInfo as AnyObject?
        }
        
        return json
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.sessionData = coder.decodeObject(forKey: "sessionData") as? SessionData
        self.screenshotUUID = coder.decodeObject(forKey: "screenshotUUID") as? UUID
        self.isSelected = coder.decodeBool(forKey: "isSelected")
        self.title = coder.decodeObject(forKey: "title") as? String
        self.isPrivate = coder.decodeBool(forKey: "isPrivate")
        self.faviconURL = coder.decodeObject(forKey: "faviconURL") as? String
        self.url = coder.decodeObject(forKey: "url") as? URL
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(sessionData, forKey: "sessionData")
        coder.encode(screenshotUUID, forKey: "screenshotUUID")
        coder.encode(isSelected, forKey: "isSelected")
        coder.encode(title, forKey: "title")
        coder.encode(isPrivate, forKey: "isPrivate")
        coder.encode(faviconURL, forKey: "faviconURL")
        coder.encode(url, forKey: "url")
    }
}

extension SavedTab {
    func toSimpleTab() -> SimpleTab {
        return SimpleTab(title: title, url: url, isPrivate: isPrivate, screenshotUUID: screenshotUUID, faviconURL: faviconURL)
    }
}
