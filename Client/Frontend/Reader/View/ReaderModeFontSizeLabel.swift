// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ReaderModeFontSizeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        text = .ReaderModeStyleFontSize
        isAccessibilityElement = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                font = UIFont(name: "SF-Pro-Text-Regular", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            case .serif,
                 .serifBold:
                font = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            }
        }
    }
}
