// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Shared

protocol ToggleModelDelegate: AnyObject {
    func toggleDidChange(_ toggleModel: ToggleModel)
}

class ToggleModel: ObservableObject {
    @Published var isEnabled = false {
        didSet {
            delegate?.toggleDidChange(self)
        }
    }
    weak var delegate: ToggleModelDelegate?

    init(isEnabled: Bool, delegate: ToggleModelDelegate? = nil) {
        self.isEnabled = isEnabled
        self.delegate = delegate
    }
}

struct CreditCardAutofillToggle: View {
    // Theming
    @Environment(\.themeType) var themeVal
    @State var textColor: Color = .clear
    @State var backgroundColor: Color = .clear
    @State var toggleTintColor: Color = .clear
    @ObservedObject var model: ToggleModel

    var body: some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Toggle(String.CreditCard.EditCard.ToggleToAllowAutofillTitle, isOn: $model.isEnabled)
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .toggleStyle(SwitchToggleStyle(tint: toggleTintColor))
            }
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
        }
        .background(backgroundColor)
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { val in
            applyTheme(theme: val.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        backgroundColor = Color(color.layer2)
        toggleTintColor = Color(color.actionPrimary)
    }
}

struct CreditCardAutofillToggle_Previews: PreviewProvider {
        static var previews: some View {
            let model = ToggleModel(isEnabled: true)

        CreditCardAutofillToggle(textColor: .gray,
                                 model: model)

        CreditCardAutofillToggle(textColor: .gray,
                                 model: model)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardAutofillToggle(textColor: .gray,
                                 model: model)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
