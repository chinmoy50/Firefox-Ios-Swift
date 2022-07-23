// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

protocol WallpaperMetadataTestProvider {
    func getExpectedMetadata(for: WallpaperJSONId) -> WallpaperMetadata
}

extension WallpaperMetadataTestProvider {
    private var lastUpdatedDate: Date {
        dateWith(year: 2001, month: 02, day: 03)
    }
    private var startDate: Date {
        dateWith(year: 2002, month: 11, day: 28)
    }
    private var endDate: Date { dateWith(year: 2022, month: 09, day: 10) }
    private var textColour: UIColor {
        UIColor(colorString: "0xADD8E6")
    }

    func getExpectedMetadata(for jsonType: WallpaperJSONId) -> WallpaperMetadata {
        switch jsonType {
        case .goodData: return getInitialMetadata()
        case .noAvailabilityRange: return getFullAvailabilityMetadata()
        case .noLocales: return getNoLocalesMetadata()
        case .availabilityStart: return getAvailabilityStartMetadata()
        case .availabilityEnd: return getAvailabilityEndMetadata()
        default:
            fatalError("No such expected data exists")
        }
    }

    private func getInitialMetadata() -> WallpaperMetadata {
        WallpaperMetadata(
                lastUpdated: lastUpdatedDate,
                collections: [
                    WallpaperCollection(
                            id: "firefox",
                            availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                            availability: WallpaperCollectionAvailability(
                                    start: startDate,
                                    end: endDate),
                            wallpapers: [
                                Wallpaper(id: "beachVibes",
                                        textColour: textColour)
                            ])
                ])
    }

    private func getFullAvailabilityMetadata() -> WallpaperMetadata {
        WallpaperMetadata(
                lastUpdated: lastUpdatedDate,
                collections: [
                    WallpaperCollection(
                            id: "firefox",
                            availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                            availability: nil,
                            wallpapers: [
                                Wallpaper(id: "beachVibes",
                                        textColour: textColour)
                            ])
                ])
    }

    private func getNoLocalesMetadata() -> WallpaperMetadata {
        WallpaperMetadata(
                lastUpdated: lastUpdatedDate,
                collections: [
                    WallpaperCollection(
                            id: "firefox",
                            availableLocales: nil,
                            availability: WallpaperCollectionAvailability(
                                    start: startDate,
                                    end: endDate),
                            wallpapers: [
                                Wallpaper(id: "beachVibes",
                                        textColour: textColour)
                            ])
                ])
    }

    func getAvailabilityStartMetadata() -> WallpaperMetadata {
        WallpaperMetadata(
                lastUpdated: lastUpdatedDate,
                collections: [
                    WallpaperCollection(
                            id: "firefox",
                            availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                            availability: WallpaperCollectionAvailability(
                                    start: startDate,
                                    end: nil),
                            wallpapers: [
                                Wallpaper(id: "beachVibes",
                                        textColour: textColour)
                            ])
                ])
    }

    func getAvailabilityEndMetadata() -> WallpaperMetadata {
        WallpaperMetadata(
                lastUpdated: lastUpdatedDate,
                collections: [
                    WallpaperCollection(
                            id: "firefox",
                            availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                            availability: WallpaperCollectionAvailability(
                                    start: nil,
                                    end: endDate),
                            wallpapers: [
                                Wallpaper(id: "beachVibes",
                                        textColour: textColour)
                            ])
                ])
    }

    private func dateWith(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let userCalendar = Calendar(identifier: .gregorian)
        guard let expectedDate = userCalendar.date(from: dateComponents) else {
            fatalError("Error creating expected date.")
        }

        return expectedDate
    }
}
