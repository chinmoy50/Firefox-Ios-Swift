// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import UIKit

protocol PhotonActionSheetProtocol {
    var tabManager: TabManager { get }
    var profile: Profile { get }
}

extension PhotonActionSheetProtocol {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate
    typealias MenuActionsDelegate = QRCodeViewControllerDelegate & SettingsDelegate & PresentingModalViewControllerDelegate & UIViewController

    func presentSheetWith(viewModel: PhotonActionSheetViewModel,
                          on viewController: PresentableVC,
                          from view: UIView) {

        let sheet = PhotonActionSheet(viewModel: viewModel)
        sheet.modalPresentationStyle = viewModel.modalStyle
        sheet.photonTransitionDelegate = PhotonActionSheetAnimator()

        if let popoverVC = sheet.popoverPresentationController, sheet.modalPresentationStyle == .popover {
            popoverVC.delegate = viewController
            popoverVC.sourceView = view
            popoverVC.sourceRect = view.bounds

            if viewModel.toolbarMenuInversed {
                let margins = viewModel.getPopOverMargins(view: view)
                popoverVC.popoverLayoutMargins = margins
            }
            popoverVC.permittedArrowDirections = viewModel.getPossibleArrowDirections(trait: viewController.traitCollection)
        }
        viewController.present(sheet, animated: true, completion: nil)
    }

    func getLongPressLocationBarActions(with urlBar: URLBarView, webViewContainer: UIView) -> [PhotonRowActions] {
        let pasteGoAction = SingleSheetItem(title: .PasteAndGoTitle, iconString: "menu-PasteAndGo") { _ in
            if let pasteboardContents = UIPasteboard.general.string {
                urlBar.delegate?.urlBar(urlBar, didSubmitText: pasteboardContents)
            }
        }.items

        let pasteAction = SingleSheetItem(title: .PasteTitle, iconString: "menu-Paste") { _ in
            if let pasteboardContents = UIPasteboard.general.string {
                urlBar.enterOverlayMode(pasteboardContents, pasted: true, search: true)
            }
        }.items

        let copyAddressAction = SingleSheetItem(title: .CopyAddressTitle, iconString: "menu-Copy-Link") { _ in
            if let url = tabManager.selectedTab?.canonicalURL?.displayURL ?? urlBar.currentURL {
                UIPasteboard.general.url = url
                SimpleToast().showAlertWithText(.AppMenuCopyURLConfirmMessage,
                                                bottomContainer: webViewContainer)
            }
        }.items

        if UIPasteboard.general.string != nil {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func getRefreshLongPressMenu(for tab: Tab) -> [PhotonRowActions] {
        guard tab.webView?.url != nil && (tab.getContentScript(name: ReaderMode.name()) as? ReaderMode)?.state != .active else {
            return []
        }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .AppMenuViewDesktopSiteTitleString : .AppMenuViewMobileSiteTitleString
        } else {
            toggleActionTitle = tab.changedUserAgent ? .AppMenuViewMobileSiteTitleString : .AppMenuViewDesktopSiteTitleString
        }
        let toggleDesktopSite = SingleSheetItem(title: toggleActionTitle, iconString: "menu-RequestDesktopSite") { _ in

            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
            }
        }.items

        if let url = tab.webView?.url, let helper = tab.contentBlocker, helper.isEnabled, helper.blockingStrengthPref == .strict {
            let isSafelisted = helper.status == .safelisted

            let title: String = !isSafelisted ? .TrackingProtectionReloadWithout : .TrackingProtectionReloadWith
            let imageName = helper.isEnabled ? "menu-TrackingProtection-Off" : "menu-TrackingProtection"
            let toggleTP = SingleSheetItem(title: title, iconString: imageName) { _ in
                ContentBlocker.shared.safelist(enable: !isSafelisted, url: url) {
                    tab.reload()
                }
            }.items
            return [toggleDesktopSite, toggleTP]
        } else {
            return [toggleDesktopSite]
        }
    }

}
