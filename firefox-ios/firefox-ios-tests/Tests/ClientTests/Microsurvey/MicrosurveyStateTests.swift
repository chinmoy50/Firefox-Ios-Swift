// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MicrosurveyStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testDismissSurveyAction() {
        let initialState = createSubject()
        let reducer = microsurveyReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)

        let action = getAction(for: .dismissSurvey)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, true)
        XCTAssertEqual(newState.showPrivacy, false)
    }

    func testSubmitSurveyAction() {
        let initialState = createSubject()
        let reducer = microsurveyReducer()

        XCTAssertEqual(initialState.showPrivacy, false)

        let action = getAction(for: .navigateToPrivacyNotice)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showPrivacy, true)
        XCTAssertEqual(newState.shouldDismiss, false)
    }

    // MARK: - Private
    private func createSubject() -> MicrosurveyState {
        return MicrosurveyState(windowUUID: .XCTestDefaultUUID)
    }

    private func microsurveyReducer() -> Reducer<MicrosurveyState> {
        return MicrosurveyState.reducer
    }

    private func getAction(for actionType: MicrosurveyMiddlewareActionType) -> MicrosurveyMiddlewareAction {
        return  MicrosurveyMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
