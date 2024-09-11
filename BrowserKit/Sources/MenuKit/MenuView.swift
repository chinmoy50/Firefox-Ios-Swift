// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public final class MenuView: UIView {
    // MARK: - UI Elements
    public var tableView: MenuTableView = .build()
    public var accountHeaderView: MenuAccountHeaderView = .build()

    // MARK: - Properties

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupView() {
        backgroundColor = .clear
        self.addSubview(accountHeaderView)
        self.addSubview(tableView)

        NSLayoutConstraint.activate([
            accountHeaderView.topAnchor.constraint(equalTo: self.topAnchor),
            accountHeaderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            accountHeaderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            accountHeaderView.heightAnchor.constraint(equalToConstant: 70),

            tableView.topAnchor.constraint(equalTo: accountHeaderView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
//
//    public func updateDataSource(with newDataSource: [MenuSection]) {
//        tableView.updateDataSource(newDataSource)
//    }
}
