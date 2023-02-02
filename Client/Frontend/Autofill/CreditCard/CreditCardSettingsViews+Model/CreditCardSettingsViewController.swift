// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import SwiftUI

class CreditCardSettingsViewController: UIViewController, ThemeApplicable {
    var themeObserver: NSObjectProtocol?
    var theme: Theme
    var viewModel: CreditCardSettingsViewModel
    var state: CreditCardSettingsState = .empty
    var startingConfig: CreditCardSettingsStartingConfig?
    
    //MARK: - Views
    var creditCardEmptyView: UIHostingController<CreditCardSettingsEmptyView>
    var creditCardListView: UIHostingController<CreditCardListView>
    var creditCardAddEditView: UIHostingController<CreditCardEditView>
    var creditCardTableViewController: CreditCardTableViewController
    //MARK: - UX
    struct UX {

    }

    //MARK: - Initializers

    init(theme: Theme,
         creditCardViewModel: CreditCardSettingsViewModel,
         startingConfig: CreditCardSettingsStartingConfig?) {
        self.theme = theme
        self.startingConfig = startingConfig
        self.viewModel = creditCardViewModel
        self.creditCardEmptyView = UIHostingController(rootView: CreditCardSettingsEmptyView())
        self.creditCardListView = UIHostingController(rootView: CreditCardListView(viewModel: viewModel.subCardListViewModel))
        self.creditCardAddEditView = UIHostingController(rootView: CreditCardEditView(viewModel: viewModel.subCardAddEditViewModel))
        self.creditCardTableViewController = CreditCardTableViewController(theme: theme)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme(theme: theme)
        viewSetup()
    }

    func viewSetup() {
        guard let emptyCreditCardView = creditCardEmptyView.view else { return }
        guard let listCreditCardView = creditCardListView.view else { return }
        guard let addEditCreditCardView = creditCardAddEditView.view else { return }
        guard let creditCardTableView = creditCardTableViewController.view else { return }
        
        creditCardTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyCreditCardView.translatesAutoresizingMaskIntoConstraints = false
        listCreditCardView.translatesAutoresizingMaskIntoConstraints = false
        addEditCreditCardView.translatesAutoresizingMaskIntoConstraints = false

        addChild(creditCardEmptyView)
        addChild(creditCardListView)
        addChild(creditCardAddEditView)
        addChild(creditCardTableViewController)
        view.addSubview(emptyCreditCardView)
        view.addSubview(listCreditCardView)
        view.addSubview(addEditCreditCardView)
        view.addSubview(creditCardTableView)

        NSLayoutConstraint.activate([
            emptyCreditCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyCreditCardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyCreditCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyCreditCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            listCreditCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listCreditCardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            listCreditCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listCreditCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            addEditCreditCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addEditCreditCardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            addEditCreditCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addEditCreditCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            creditCardTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            creditCardTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            creditCardTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            creditCardTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // Hide all the views initially until we update the state
        hideAllViews()

        // Setup state and update view
        setupSate()
    }

    func setupSate() {
        // check if there are any starting config

        guard let startingConfig = startingConfig else {
            //Check if we have any credit cards to show in the list
            viewModel.listCreditCard { creditCards in
                guard let creditCards = creditCards, !creditCards.isEmpty else {
                    DispatchQueue.main.async {
                        self.updateState(type: .empty)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.creditCardTableViewController.creditCards = creditCards
                    self.updateState(type: .list)
                }
            }

            updateState(type: .empty)
            return
        }

        startingConfig.actionToPerform
        updateState(type: .list)
    }

    func updateState(type: CreditCardSettingsState) {
        hideAllViews()
        switch type {
        case .empty:
            creditCardEmptyView.view.isHidden = false
        case .add:
            creditCardAddEditView.view.isHidden = false
        case .edit:
            creditCardAddEditView.view.isHidden = false
        case .list:
//            creditCardListView.view.isHidden = false
            creditCardTableViewController.tableView.reloadData()
            creditCardTableViewController.view.isHidden = false
        }
    }

    func setupAdd() {
        
    }

    func setupEdit() {
        // Show creditCardModifierViewController with edit
    }

    func setupList() {
        
    }

    func hideAllViews() {
        creditCardEmptyView.view.isHidden = true
        creditCardListView.view.isHidden = true
        creditCardAddEditView.view.isHidden = true
        creditCardListView.view.isHidden = true
    }

    func applyTheme(theme: Theme) {
        view.backgroundColor = theme.colors.layer1
    }
}
