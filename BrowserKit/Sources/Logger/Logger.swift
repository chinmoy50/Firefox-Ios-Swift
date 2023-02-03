// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol Logger {
    var crashedLastLaunch: Bool { get }

    func setup(sendUsageData: Bool)

    /// Log a new message to the logging system
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The level of the log
    ///   - category: The category of the log
    ///   - extra: Optional extras to send, in a dictionnary format
    ///   - description: Optional description to add to the message
    ///   - sendToSentry: Set to true to send the log to Sentry as well, false by default
    ///   - file: The file this log is located in
    ///   - function: The function this log is located in
    ///   - line: The line number this log is located in
    func log(_ message: String,
             level: LoggerLevel,
             category: LoggerCategory,
             extra: [String: String]?,
             description: String?,
             sendToSentry: Bool,
             file: String,
             function: String,
             line: Int)

    /// Provide method to save log files to document folder so we can retrieve it more easily on devices
    func copyLogsToDocuments()
}

public extension Logger {
    func log(_ message: String,
             level: LoggerLevel,
             category: LoggerCategory,
             extra: [String: String]? = nil,
             description: String? = nil,
             sendToSentry: Bool = false,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {
        self.log(message,
                 level: level,
                 category: category,
                 extra: extra,
                 description: description,
                 sendToSentry: sendToSentry,
                 file: file,
                 function: function,
                 line: line)
    }
}
