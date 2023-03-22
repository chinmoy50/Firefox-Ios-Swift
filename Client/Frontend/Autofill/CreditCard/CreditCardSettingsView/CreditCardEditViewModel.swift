// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common
import Storage

enum CreditCardEditState: String, Equatable, CaseIterable {
    case add
    case edit
    case view

    enum leftBarButtonState: String, Equatable, CaseIterable {
        case Close
        case Cancel

        var title: String {
            switch self {
            case .Cancel:
                return String.CreditCard.EditCard.CancelNavBarButtonLabel
            case .Close:
                return String.CreditCard.EditCard.CloseNavBarButtonLabel
            }
        }
    }

    enum rightBarButtonState: String, Equatable, CaseIterable {
        case Save
        case Edit

        var title: String {
            switch self {
            case .Save:
                return String.CreditCard.EditCard.SaveNavBarButtonLabel
            case .Edit:
                return String.CreditCard.EditCard.EditNavBarButtonLabel
            }
        }
    }

    var title: String {
        switch self {
        case .add:
            return String.CreditCard.EditCard.AddCreditCardTitle
        case .view:
            return String.CreditCard.EditCard.ViewCreditCardTitle
        case .edit:
            return String.CreditCard.EditCard.EditCreditCardTitle
        }
    }

    var leftBarBtn: leftBarButtonState {
        switch self {
        case .add, .view:
            return .Close
        case .edit:
            return .Cancel
        }
    }

    var rightBarBtn: rightBarButtonState {
        switch self {
        case .add, .edit:
            return .Save
        case .view:
            return .Edit
        }
    }
}

class CreditCardEditViewModel: ObservableObject {
    typealias CreditCardText = String.CreditCard.Alert

    let profile: Profile
    let autofill: RustAutofill
    let creditCard: CreditCard?

    @Published var state: CreditCardEditState
    @Published var errorState: String = ""
    @Published var enteredValue: String = ""
    @Published var cardType: CreditCardType?
    @Published var nameIsValid = true
    @Published var numberIsValid = true
    @Published var expirationIsValid = true
    @Published var nameOnCard: String = "" {
        didSet (val) {
            nameIsValid = !nameOnCard.isEmpty
        }
    }

    @Published var expirationDate: String = "" {
        didSet (val) {
            guard !val.isEmpty else {
                expirationIsValid = false
                return
            }
            expirationIsValid = true
        }
    }

    @Published var cardNumber: String = "" {
        willSet (val) {
            guard let intVal = Int(val),
                  CreditCardValidator(creditCardNumber: intVal).isValid() else {
                numberIsValid = false
                return
            }
            // Set the card type
            self.cardType = CreditCardValidator(creditCardNumber: intVal).cardType()
            numberIsValid = true
        }
    }

    var signInRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: Text(CreditCardText.RemoveCardSublabel),
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCard: creditCard)
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {})
    }

    var regularRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: nil,
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCard: creditCard)
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {}
        )
    }

    var removeButtonDetails: RemoveCardButton.AlertDetails {
        return profile.hasSyncableAccount() ? signInRemoveButtonDetails : regularRemoveButtonDetails
    }

    init(profile: Profile,
         creditCard: CreditCard? = nil
    ) {
        self.profile = profile
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = .add
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String,
         creditCard: CreditCard? = nil,
         state: CreditCardEditState
    ) {
        self.profile = profile
        self.errorState = errorState
        self.enteredValue = enteredValue
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = state
    }

    // MARK: - Helpers

    private func removeSelectedCreditCard(creditCard: CreditCard) {
        autofill.deleteCreditCard(id: creditCard.guid) { _, error in
            // no-op
        }
    }

    public func updateState(state: CreditCardEditState) {
        self.state = state
    }

    public func saveCreditCard(completion: @escaping (CreditCard?, Error?) -> Void) {
        guard let cardType = cardType,
              nameIsValid,
              numberIsValid,
              let month = Int64(expirationDate),
              let year = Int64(expirationDate) else {
            return
        }

        let creditCard = UnencryptedCreditCardFields(
                         ccName: nameOnCard,
                         ccNumber: cardNumber,
                         ccNumberLast4: String(cardNumber.suffix(4)),
                         ccExpMonth: month,
                         ccExpYear: year,
                         ccType: cardType.rawValue)

        autofill.addCreditCard(creditCard: creditCard, completion: completion)
    }

    public func clearValues() {
        nameOnCard = ""
        cardNumber = ""
        expirationDate = ""
        nameIsValid = true
        expirationIsValid = true
        numberIsValid = true
    }
}
