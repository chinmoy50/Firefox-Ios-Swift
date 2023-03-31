// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Client

class CreditCardValidatorTests: XCTestCase {
    private var creditCardValidator: CreditCardValidator!

    override func setUp() {
        super.setUp()

        creditCardValidator = CreditCardValidator()
    }

    override func tearDown() {
        super.tearDown()

        creditCardValidator = nil
    }

    func testCardTypeForVisa() {
        let result = creditCardValidator.cardTypeFor(4004100120023003)

        XCTAssertEqual(result, .visa)
    }

    func testCardTypeForMastercard() {
        let result = creditCardValidator.cardTypeFor(5502100120023003)

        XCTAssertEqual(result, .mastercard)
    }

    func testCardTypeForAmex() {
        let result = creditCardValidator.cardTypeFor(34705123451234)

        XCTAssertEqual(result, .amex)
    }

    func testCardTypeForDiners() {
        let result = creditCardValidator.cardTypeFor(30068114212341234)

        XCTAssertEqual(result, .diners)
    }

    func testCardTypeForJCB() {
        let result = creditCardValidator.cardTypeFor(2131350313123456)

        XCTAssertEqual(result, .jcb)
    }

    func testCardTypeForDiscover() {
        let result = creditCardValidator.cardTypeFor(6011502031234123)

        XCTAssertEqual(result, .discover)
    }

    func testCardTypeForMIR() {
        let result = creditCardValidator.cardTypeFor(2060123412341234)

        XCTAssertEqual(result, .mir)
    }

    func testCardTypeForUnionPay() {
        let result = creditCardValidator.cardTypeFor(6240123412341216)

        XCTAssertEqual(result, .unionpay)
    }

    func testCardNumberInvalidForBeyondLimit() {
        _ = XCTSkip()
        // Fix int overflow issue before uncommenting these tests

        // 20 character input
//        let result = creditCardValidator.isCardNumberValidFor(card: 6923965692209765999)
//        XCTAssertFalse(result)
        // 30 character input (technically impossible, but just in case)
//        result = creditCardValidator.isCardNumberValidFor(card: 123456789012345678901234567890)
//        XCTAssertFalse(result)
    }

    func testCardNumberInvalidForUnderLimit() {
        // 10 character input
        var result = creditCardValidator.isCardNumberValidFor(card: 1234567890)
        XCTAssertFalse(result)

        result = creditCardValidator.isCardNumberValidFor(card: 1)
        XCTAssertFalse(result)
    }

    func testExpirationIsValidOnWellFormedInput() {
        var result = creditCardValidator.isExpirationValidFor(date: "1230")
        XCTAssert(result)

        result = creditCardValidator.isExpirationValidFor(date: "0926")
        XCTAssert(result)
    }

    func testExpirationIsInvalidOnIncorrectInput() {
        var result = creditCardValidator.isExpirationValidFor(date: "0000")
        XCTAssertFalse(result)

        result = creditCardValidator.isExpirationValidFor(date: "1525")
        XCTAssertFalse(result)
    }

    func tetsExpirationIsInvalidOnBlankInput() {
        let result = creditCardValidator.isExpirationValidFor(date: "")
        XCTAssertFalse(result)
    }

    func testExpirationIsInvalidOnNonNumericInput() {
        let result = creditCardValidator.isExpirationValidFor(date: "Firefox da best")
        XCTAssertFalse(result)
    }
}
