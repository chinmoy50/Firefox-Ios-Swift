/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WidgetKit
import SwiftUI
import Shared

struct Provider: TimelineProvider {
    public typealias Entry = SimpleEntry

    public func snapshot(with context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

var scheme: String {
    guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
        // Something went wrong/weird, but we should fallback to the public one.
        return "firefox"
    }
    return string
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
}

struct NewTodayEntryView : View {
    @Environment(\.widgetFamily) var family
    static var copiedURL: URL?
    static var searchedText : String?

    @ViewBuilder
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false", query: "open-url"), label: String.NewTabButtonLabel)
                ImageButtonWithLabel(imageName: "smallPrivateMask", url: linkToContainingApp("?private=true", query: "open-url"), label: String.NewPrivateTabButtonLabel, isPrivate: true)
            }
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "copy_link_icon", url: linkToContainingApp(query: "open-copied"), label: String.GoToCopiedLinkLabelV2)
                ImageButtonWithLabel(imageName: "delete", url: linkToContainingApp(query: "close-private-tabs"), label: String.closePrivateTabsButtonLabel, isPrivate: true)
            }
        }
        .padding(10.0)
        .background(Color("WidgetBackground"))
    }

    fileprivate func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}

@main
struct NewTodayWidget: Widget {
    private let kind: String = "Search"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(), placeholder: NewTodayEntryView()) { entry in
            NewTodayEntryView()
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Search")
        .description("This is an example widget.")
    }
}

struct NewTodayPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            NewTodayEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NewTodayEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)

            NewTodayEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.sizeCategory, .small)

            NewTodayEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.sizeCategory, .accessibilityLarge)
        }
    }
}
