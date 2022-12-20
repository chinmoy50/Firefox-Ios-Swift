// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared

struct BackForwardCellViewModel {
    var site: Site
    var connectingForwards: Bool
    var connectingBackwards: Bool
    var isCurrentTab: Bool
    var strokeBackgroundColor: UIColor

    var cellTittle: String {
        return !site.title.isEmpty ? site.title : site.url
    }
}

class BackForwardTableViewCell: UITableViewCell, ThemeApplicable {
    private struct UX {
        static let faviconWidth: CGFloat = 29
        static let faviconPadding: CGFloat = 20
        static let labelPadding: CGFloat = 20
        static let iconSize = CGSize(width: 23, height: 23)
        static let fontSize: CGFloat = 12
    }

    private lazy var faviconView: UIImageView = .build { imageView in
        imageView.image = FaviconFetcher.defaultFavicon
        imageView.layer.cornerRadius = 6
        imageView.layer.borderWidth = 0.5
        imageView.layer.masksToBounds = true
        imageView.contentMode = .center
    }

    lazy var label: UILabel = .build { _ in }

    var viewModel: BackForwardCellViewModel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    func setupLayout() {
        backgroundColor = UIColor.clear
        selectionStyle = .none

        contentView.addSubview(faviconView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            faviconView.heightAnchor.constraint(equalToConstant: UX.faviconWidth),
            faviconView.widthAnchor.constraint(equalToConstant: UX.faviconWidth),
            faviconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                 constant: UX.faviconPadding),

            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: faviconView.trailingAnchor, constant: UX.labelPadding),
            label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -UX.labelPadding)
        ])
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        var startPoint = CGPoint(
            x: rect.origin.x + UX.faviconPadding + UX.faviconWidth * 0.5 + safeAreaInsets.left,
            y: rect.origin.y + (viewModel.connectingForwards ?  0 : rect.size.height/2))
        var endPoint   = CGPoint(
            x: rect.origin.x + UX.faviconPadding + UX.faviconWidth * 0.5 + safeAreaInsets.left,
            y: rect.origin.y + rect.size.height - (viewModel.connectingBackwards ? 0 : rect.size.height/2))

        // flip the x component if RTL
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            startPoint.x = rect.origin.x - startPoint.x + rect.size.width
            endPoint.x = rect.origin.x - endPoint.x + rect.size.width
        }

        context.saveGState()
        context.setLineCap(.square)
        context.setStrokeColor(viewModel.strokeBackgroundColor.cgColor)
        context.setLineWidth(1.0)
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
        context.restoreGState()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = UIColor(white: 0, alpha: 0.1)
        } else {
            self.backgroundColor = UIColor.clear
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }

    func configure(viewModel: BackForwardCellViewModel, theme: Theme) {
        self.viewModel = viewModel

        faviconView.setFavicon(forSite: viewModel.site) { [weak self] in
            if InternalURL.isValid(url: viewModel.site.tileURL) {
                self?.faviconView.image = UIImage(named: ImageIdentifiers.firefoxFavIcon)
                self?.faviconView.image = self?.faviconView.image?.createScaled(UX.iconSize)
                return
            }

            self?.faviconView.image = self?.faviconView.image?.createScaled(UX.iconSize)
        }

        label.text = viewModel.cellTittle
        if viewModel.isCurrentTab {
            label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body,
                                                                           size: UX.fontSize)
        } else {
            label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                       size: UX.fontSize)
        }
        setNeedsLayout()
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        label.textColor = theme.colors.textPrimary
        viewModel.strokeBackgroundColor = theme.colors.iconPrimary
        faviconView.layer.borderColor = theme.colors.borderPrimary.cgColor
        // setFavicon applies a color background to the imageView
        // if the color is clear we default to white background
        if faviconView.backgroundColor == nil || faviconView.backgroundColor == .clear {
            faviconView.backgroundColor = theme.colors.layer6
        }
    }
}
