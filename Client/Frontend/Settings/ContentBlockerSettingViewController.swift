/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

extension BlockingStrength {
    var settingTitle: String {
        switch self {
        case .basic:
            return Strings.TrackingProtectionOptionBlockListLevelStandard
        case .strict:
            return Strings.TrackingProtectionOptionBlockListLevelStrict
        }
    }

    static func accessibilityId(for strength: BlockingStrength) -> String {
        switch strength {
        case .basic:
            return "Settings.TrackingProtectionOption.BlockListBasic"
        case .strict:
            return "Settings.TrackingProtectionOption.BlockListStrict"
        }
    }
}

// Additional information shown when the info accessory button is tapped.
class TPAccessoryInfo: ThemedTableViewController {
    var isStrictMode = false

    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 130
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.tableHeaderView = headerView()

        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        applyTheme()
    }

    func headerView() -> UIView {
        let stack = UIStackView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
        stack.axis = .vertical

        let label = UILabel()
        label.text = isStrictMode ? Strings.TPAccessoryInfoTitleStrict : Strings.TPAccessoryInfoTitleBasic
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        label.textColor = UIColor.theme.tableView.headerTextLight

        let header = UILabel()
        header.text = Strings.TPAccessoryInfoBlocksTitle
        header.font = DynamicFontHelper.defaultHelper.DefaultMediumBoldFont
        header.textColor = UIColor.theme.tableView.headerTextLight

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(header)

        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true

        let topStack = UIStackView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
        topStack.axis = .vertical
        let sep = UIView()
        topStack.addArrangedSubview(stack)
        topStack.addArrangedSubview(sep)
        topStack.spacing = 10

        topStack.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        topStack.isLayoutMarginsRelativeArrangement = true

        sep.backgroundColor = UIColor.theme.tableView.separator
        sep.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }
        return topStack
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isStrictMode ? 5 : 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(imageLiteralResourceName: "tp-socialtracker")
                cell.textLabel?.text = Strings.TPSocialBlocked
            } else {
                cell.textLabel?.text = Strings.TPCategoryDescriptionSocial
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(imageLiteralResourceName: "tp-cookie")
                cell.textLabel?.text = Strings.TPCrossSiteBlocked
            } else {
                cell.textLabel?.text = Strings.TPCategoryDescriptionCrossSite
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(imageLiteralResourceName: "tp-cryptominer")
                cell.textLabel?.text = Strings.TPCryptominersBlocked
            } else {
                cell.textLabel?.text = Strings.TPCategoryDescriptionCryptominers
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(imageLiteralResourceName: "tp-fingerprinter")
                cell.textLabel?.text = Strings.TPFingerprintersBlocked
            } else {
                cell.textLabel?.text = Strings.TPCategoryDescriptionFingerprinters
            }
        } else if indexPath.section == 4 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(imageLiteralResourceName: "tp-contenttracker")
                cell.textLabel?.text = Strings.TPContentBlocked
            } else {
                cell.textLabel?.text = "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work."
            }
        }
        cell.imageView?.tintColor = UIColor.theme.tableView.rowText
        if indexPath.row == 1 {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        }
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.backgroundColor = .clear
        return cell
    }
}

class ContentBlockerSettingViewController: SettingsTableViewController {
    let prefs: Prefs
    var currentBlockingStrength: BlockingStrength

    init(prefs: Prefs) {
        self.prefs = prefs

        currentBlockingStrength = prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) ?? .basic

        super.init(style: .grouped)

        self.title = Strings.SettingsTrackingProtectionSectionName
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let strengthSetting: [CheckmarkSetting] = BlockingStrength.allOptions.map { option in
            let id = BlockingStrength.accessibilityId(for: option)
            let setting = CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), style: .leftSide, subtitle: nil, accessibilityIdentifier: id, isChecked: {
                return option == self.currentBlockingStrength
            }, onChecked: {
                self.currentBlockingStrength = option
                self.prefs.setString(self.currentBlockingStrength.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
                TabContentBlocker.prefsChanged()
                self.tableView.reloadData()
                LeanPlumClient.shared.track(event: .trackingProtectionSettings, withParameters: ["Strength option": option.rawValue])
                UnifiedTelemetry.recordEvent(category: .action, method: .change, object: .setting, value: ContentBlockingConfig.Prefs.StrengthKey, extras: ["to": option.rawValue])
            })

            setting.onAccessoryButtonTapped = {
                let vc = TPAccessoryInfo()
                vc.isStrictMode = option == .strict
                self.navigationController?.pushViewController(vc, animated: true)
            }

            return setting
        }

        let enabledSetting = BoolSetting(prefs: profile.prefs, prefKey: ContentBlockingConfig.Prefs.EnabledKey, defaultValue: ContentBlockingConfig.Defaults.NormalBrowsing, attributedTitleText: NSAttributedString(string: Strings.TrackingProtectionEnableTitle)) { [weak self] enabled in
            TabContentBlocker.prefsChanged()
            strengthSetting.forEach { item in
                item.enabled = enabled
            }
            self?.tableView.reloadData()
        }

        let firstSection = SettingSection(title: nil, footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffFooter), children: [enabledSetting])

        let optionalFooterTitle = NSAttributedString(string: Strings.TrackingProtectionProtectionStrictInfoFooter)

        // The bottom of the block lists section has a More Info button, implemented as a custom footer view,
        // SettingSection needs footerTitle set to create a footer, which we then override the view for.
        let blockListsTitle = Strings.TrackingProtectionOptionProtectionLevelTitle
        let secondSection = SettingSection(title: NSAttributedString(string: blockListsTitle), footerTitle: optionalFooterTitle, children: strengthSetting)
        return [firstSection, secondSection]
    }

    // The first section header gets a More Info link
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let _defaultFooter = super.tableView(tableView, viewForFooterInSection: section) as? ThemedTableSectionHeaderFooterView
        guard let defaultFooter = _defaultFooter, section > 0 else {
            return _defaultFooter
        }

        if currentBlockingStrength == .basic {
            return nil
        }

        // TODO: Get a dedicated string for this.
        let title = NSLocalizedString("More Info…", tableName: "SendAnonymousUsageData", comment: "Re-using more info label from 'anonymous usage data' item for showing a 'More Info' link on the Tracking Protection settings screen.")

        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        attributes[NSAttributedString.Key.foregroundColor] = UIColor.theme.general.highlightBlue

        let button = UIButton()
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.addTarget(self, action: #selector(moreInfoTapped), for: .touchUpInside)

        defaultFooter.addSubview(button)

        button.snp.makeConstraints { (make) in
            make.top.equalTo(defaultFooter.titleLabel.snp.bottom)
            make.leading.equalTo(defaultFooter.titleLabel)
        }

        return defaultFooter
    }

    @objc func moreInfoTapped() {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("tracking-protection-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }
}
