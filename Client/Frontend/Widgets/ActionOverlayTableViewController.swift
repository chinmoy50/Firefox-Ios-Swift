/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

class ActionOverlayTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private(set) var actions: [ActionOverlayTableViewAction]

    private var site: Site
    private var tableView = UITableView()
    private var headerImage: UIImage?
    private var headerImageBackgroundColor: UIColor?
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(ActionOverlayTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        return tapRecognizer
    }()

    lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        visualEffectView.frame = self.view.bounds
        visualEffectView.alpha = 0.90
        return visualEffectView
    }()

    init(site: Site, actions: [ActionOverlayTableViewAction], siteImage: UIImage?, siteBGColor: UIColor?) {
        self.site = site
        self.actions = actions
        self.headerImage = siteImage
        self.headerImageBackgroundColor = siteBGColor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.4)
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.registerClass(ActionOverlayTableViewCell.self, forCellReuseIdentifier: "ActionOverlayTableViewCell")
        tableView.registerClass(ActionOverlayTableViewHeader.self, forHeaderFooterViewReuseIdentifier: "ActionOverlayTableViewHeader")
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.scrollEnabled = true
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .None
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        tableView.snp_makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(290)
            make.height.lessThanOrEqualTo(UIScreen.mainScreen().bounds.size.height).priorityHigh()
            make.height.equalTo(74 + actions.count * 56).priorityLow()
        }
    }

    func dismiss(gestureRecognizer: UIGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func updateViewConstraints() {
        tableView.snp_updateConstraints { make in
            make.height.lessThanOrEqualTo(UIScreen.mainScreen().bounds.size.height).priorityHigh()
        }
        super.updateViewConstraints()
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let action = actions[indexPath.row]
        guard let handler = actions[indexPath.row].handler else {
            return
        }
        return handler(action)
    }

    func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 74
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActionOverlayTableViewCell", forIndexPath: indexPath) as! ActionOverlayTableViewCell
        let action = actions[indexPath.row]
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("ActionOverlayTableViewHeader") as! ActionOverlayTableViewHeader
        header.configureWithSite(site, image: headerImage, imageBackgroundColor: headerImageBackgroundColor)
        return header
    }
}

class ActionOverlayTableViewHeader: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = .Left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        titleLabel.textColor = SimpleHighlightCellUX.DescriptionLabelColor
        titleLabel.textAlignment = .Left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.Center
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        return siteImageView
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        descriptionLabel.numberOfLines = 1
        titleLabel.numberOfLines = 1

        contentView.backgroundColor = UIConstants.PanelBackgroundColor

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(titleLabel)

        siteImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(12)
            make.size.equalTo(SimpleHighlightCellUX.SiteImageViewSize)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(12)
            make.trailing.equalTo(contentView).inset(12)
            make.top.equalTo(siteImageView).offset(7)
        }

        descriptionLabel.snp_remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(siteImageView).inset(7)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithSite(site: Site, image: UIImage?, imageBackgroundColor: UIColor?) {
        siteImageView.backgroundColor = imageBackgroundColor

        if AppConstants.MOZ_AS_PANEL {
            siteImageView.image = image?.createScaled(SimpleHighlightCellUX.IconSize) ?? SimpleHighlightCellUX.PlaceholderImage
        } else {
            siteImageView.image = image ?? SimpleHighlightCellUX.PlaceholderImage
            siteImageView.contentMode = UIViewContentMode.ScaleAspectFill
        }

        titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        descriptionLabel.text = site.tileURL.baseDomain
    }
}
