// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared

struct SearchSettingsState: ScreenState, Equatable {
    init(_ appState: AppState) {
    }

    static let reducer: Reducer<Self> = { state, action in
        return state
    }
}
