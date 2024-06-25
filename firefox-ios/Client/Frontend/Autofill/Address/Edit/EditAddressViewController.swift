// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import SwiftUI
import Common
import struct MozillaAppServices.UpdatableAddressFields

class EditAddressViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, Themeable {
    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    private lazy var removeButton: RemoveAddressButton = {
        let button = RemoveAddressButton()
        button.setTitle(.Addresses.Settings.Edit.RemoveAddressButtonTitle, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(
            UIAction { [weak self] _ in self?.presentRemoveAddressAlert() },
            for: .touchUpInside
        )
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [webView, removeButton])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    var model: AddressListViewModel
    private let logger: Logger
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var currentWindowUUID: WindowUUID? { model.windowUUID }

    init(
        themeManager: ThemeManager,
        model: AddressListViewModel,
        logger: Logger = DefaultLogger.shared
    ) {
        self.model = model
        self.logger = logger
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebView()
        setupActivityIndicator()
        setupRemoveButton()
        listenForThemeChange(view)
    }

    private func setupActivityIndicator() {
        self.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupRemoveButton() {
        removeButton.isHidden = true
        removeButton.applyTheme(
            theme: themeManager.getCurrentTheme(for: currentWindowUUID)
        )
        NSLayoutConstraint.activate([
            removeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupWebView() {
        self.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        model.toggleEditModeAction = { [weak self] isEditMode in
            self?.removeButton.isHidden = !isEditMode
            self?.evaluateJavaScript("toggleEditMode(\(isEditMode));")
        }

        model.saveAction = { [weak self] completion in
            self?.getCurrentFormData(completion: completion)
        }

        if let url = Bundle.main.url(forResource: "AddressFormManager", withExtension: "html") {
            let request = URLRequest(url: url)
            webView.loadFileURL(url, allowingReadAccessTo: url)
            webView.load(request)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        do {
            let javascript = try model.getInjectJSONDataInit()
            self.evaluateJavaScript(javascript)
            if case .add = model.destination {
                self.evaluateJavaScript("toggleEditMode(true);")
            }
        } catch {
            self.logger.log(
                "Error injecting JavaScript",
                level: .warning,
                category: .autofill,
                description: "Error evaluating JavaScript: \(error.localizedDescription)"
            )
        }
    }

    private func getCurrentFormData(completion: @escaping (UpdatableAddressFields) -> Void) {
        self.webView.evaluateJavaScript("getCurrentFormData();") { [weak self] result, error in
            if let error = error {
                self?.logger.log(
                    "JavaScript execution error",
                    level: .warning,
                    category: .autofill,
                    description: "JavaScript execution error: \(error.localizedDescription)"
                )
                return
            }

            guard let resultDict = result as? [String: Any] else {
                self?.logger.log(
                    "Result is nil or not a dictionary",
                    level: .warning,
                    category: .autofill,
                    description: "Result is nil or not a dictionary"
                )
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: resultDict, options: [])
                let decoder = JSONDecoder()
                decoder.userInfo[.formatStyleKey] = FormatStyle.kebabCase
                let address = try decoder.decode(UpdatableAddressFields.self, from: jsonData)
                completion(address)
            } catch {
                self?.logger.log(
                    "Failed to decode dictionary",
                    level: .warning,
                    category: .autofill,
                    description: "Failed to decode dictionary \(error.localizedDescription)"
                )
            }
        }
    }

    private func evaluateJavaScript(_ jsCode: String) {
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                self.logger.log(
                    "JavaScript execution error",
                    level: .warning,
                    category: .autofill,
                    description: "JavaScript execution error: \(error.localizedDescription)"
                )
            }
        }
    }

    func applyTheme() {
        guard let currentWindowUUID else { return }
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        removeButton.applyTheme(theme: theme)
        let isDarkTheme = theme.type == .dark
        evaluateJavaScript("setTheme(\(isDarkTheme));")
    }

    func presentRemoveAddressAlert() {
        let alertController = UIAlertController(
            title: String.Addresses.Settings.Edit.RemoveAddressTitle,
            message: model.hasSyncableAccount() ? String.Addresses.Settings.Edit.RemoveAddressMessage : nil,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: String.Addresses.Settings.Edit.CancelButtonTitle,
            style: .cancel,
            handler: nil
        ))

        alertController.addAction(UIAlertAction(
            title: String.Addresses.Settings.Edit.RemoveButtonTitle,
            style: .destructive,
            handler: { _ in
                self.model.removeConfimationButtonTap()
            }
        ))

        self.present(alertController, animated: true, completion: nil)
    }
}

struct EditAddressViewControllerRepresentable: UIViewControllerRepresentable {
    var model: AddressListViewModel

    func makeUIViewController(context: Context) -> EditAddressViewController {
        return EditAddressViewController(
            themeManager: AppContainer.shared.resolve(),
            model: model
        )
    }

    func updateUIViewController(_ uiViewController: EditAddressViewController, context: Context) {
        // Here you can update the view controller when your SwiftUI state changes.
        // Since the WebModel is passed at creation, there might not be much to do here.
    }
}
