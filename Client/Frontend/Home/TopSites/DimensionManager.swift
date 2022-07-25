// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TopSitesSectionDimension {
    var numberOfRows: Int
    var numberOfTilesPerRow: Int
}

struct TopSitesUIInterface {
    var isLandscape: Bool = UIWindow.isLandscape
    var isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    var horizontalSizeClass: UIUserInterfaceSizeClass

    init(trait: UITraitCollection) {
        horizontalSizeClass = trait.horizontalSizeClass
    }
}

// Laurie - documentation
protocol TopSitesDimension {
    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             interface: TopSitesUIInterface
    ) -> TopSitesSectionDimension
}

class TopSitesDimensionImplementation: TopSitesDimension {

    struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    }

    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             interface: TopSitesUIInterface
    ) -> TopSitesSectionDimension {
        let numberOfTilesPerRow = getNumberOfTilesPerRow(for: interface)
        let numberOfRows = getNumberOfRows(for: sites,
                                           numberOfRows: numberOfRows,
                                           numberOfTilesPerRow: numberOfTilesPerRow)
        return TopSitesSectionDimension(numberOfRows: numberOfRows,
                                        numberOfTilesPerRow: numberOfTilesPerRow)
    }

    // Adjust number of rows depending on the what the users want, and how many sites we actually have.
    // We hide rows that are only composed of empty cells
    /// - Parameter numberOfTilesPerRow: The number of tiles per row the user will see
    /// - Returns: The number of rows the user will see on screen
    private func getNumberOfRows(for sites: [TopSite],
                                 numberOfRows: Int,
                                 numberOfTilesPerRow: Int) -> Int {
        let totalCellCount = numberOfTilesPerRow * numberOfRows
        let emptyCellCount = totalCellCount - sites.count

        // If there's no empty cell, no clean up is necessary
        guard emptyCellCount > 0 else { return numberOfRows }

        let numberOfEmptyCellRows = Double(emptyCellCount / numberOfTilesPerRow)
        return numberOfRows - Int(numberOfEmptyCellRows.rounded(.down))
    }

    /// Get the number of tiles per row the user will see. This depends on the UI interface the user has.
    /// - Parameter interface: Tile number is based on layout, this param contains the parameters needed to computer the tile number
    /// - Returns: The number of tiles per row the user will see
    private func getNumberOfTilesPerRow(for interface: TopSitesUIInterface) -> Int {
        if interface.isIphone {
            return interface.isLandscape ? 8 : 4

        } else {
            // The number of items in a row is equal to the number of top sites in a row * 2
            var numItems = Int(UX.numberOfItemsPerRowForSizeClassIpad[interface.horizontalSizeClass])
            if !interface.isLandscape || (interface.horizontalSizeClass == .compact && interface.isLandscape) {
                numItems = numItems - 1
            }
            return numItems * 2
        }
    }
}
