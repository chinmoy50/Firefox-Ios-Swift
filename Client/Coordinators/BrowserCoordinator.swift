// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class BrowserCoordinator: BaseCoordinator {
    var launchCoordinator: LaunchCoordinator?

    func start(launchManager: LaunchManager) {
        if !launchManager.canLaunchFromSceneCoordinator, let launchType = launchManager.getLaunchType() {
            launchCoordinator = LaunchCoordinator(router: router)
            launchCoordinator?.start(with: launchType)
        }
    }
}
