// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/**
 * A specialized version of UIButton for use in SnackBars. These are displayed evenly
 * spaced in the bottom of the bar. The main convenience of these is that you can pass
 * in a callback in the constructor (although these also style themselves appropriately).
 */
typealias SnackBarCallback = (_ bar: SnackBar) -> Void
class SnackButton: UIButton, ThemeApplicable {
    let callback: SnackBarCallback?
    var bar: SnackBar?

    private var highlightedTintColor: UIColor!
    private var normalTintColor: UIColor = .clear
    private var themeTextColor: UIColor!

    private struct UX {
        static let borderWidth: CGFloat = 0.5
        static let fontSize: CGFloat = 17
    }

    let separator: UIView = .build()

    override open var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? highlightedTintColor : normalTintColor
        }
    }

    init(title: String, accessibilityIdentifier: String, bold: Bool = false, callback: @escaping SnackBarCallback) {
        self.callback = callback

        super.init(frame: .zero)

        if bold {
            titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: UX.fontSize)
        } else {
            titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.fontSize)
        }
        titleLabel?.adjustsFontForContentSizeCategory = true
        setTitle(title, for: .normal)
        addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onClick() {
        if let bar { callback?(bar) }
    }

    func drawSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.widthAnchor.constraint(equalToConstant: UX.borderWidth)
        ])
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        highlightedTintColor = colors.actionPrimaryHover
        themeTextColor = theme.type == .light ? colors.textPrimary : colors.textInverted
        setTitleColor(themeTextColor, for: .normal)
        separator.backgroundColor = colors.borderPrimary
    }
}
