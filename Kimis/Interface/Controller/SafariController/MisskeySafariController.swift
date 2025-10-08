//
//  MisskeySafariController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Combine
import UIKit
import WebKit

class MisskeySafariController: ViewController, WKNavigationDelegate {
    var webView: WKWebView!

    let progressBar = UIProgressView()

    init() {
        super.init(nibName: nil, bundle: nil)

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let contentController = WKUserContentController()

        let tokenInjector = """
        localStorage['account'] = JSON.stringify({
            'token' : '\(source?.receipt.token ?? "")'
        })
        """
        let tokenInjectorScript = WKUserScript(
            source: tokenInjector,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(tokenInjectorScript)

        let langOverride = """
        Object.defineProperties(Navigator.prototype, {
                language: {
                        value: 'en',
                        configurable: false,
                        enumerable: true,
                        writable: false
                },
                languages: {
                        value: ['en'],
                        configurable: false,
                        enumerable: true,
                        writable: false
                }
        });
        """
        let langOverrideScript = WKUserScript(
            source: langOverride,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(langOverrideScript)

        config.userContentController = contentController
        let cookie = HTTPCookie(properties: [
            .domain: source?.receipt.host ?? "localhost",
            .path: "/",
            .name: "token",
            .value: source?.receipt.token ?? "",
            .secure: "TRUE",
            .expires: NSDate(timeIntervalSinceNow: 100_000_000),
        ])!
        config.websiteDataStore.httpCookieStore.setCookie(cookie)
        webView = .init(frame: .zero, configuration: config)
        webView.navigationDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        webView.isOpaque = false
        webView.backgroundColor = .platformBackground
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        view.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(webView)
            make.height.equalTo(2)
        }
        navigationItem.rightBarButtonItems = [
            .init(title: L10n.text("Done"), style: .done, target: self, action: #selector(doneTapped)),
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        load()
    }

    func load() {
        if let host = source?.host {
            let url = host.appendingPathComponent("settings")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            webView.load(request)
        }
    }

    @objc func doneTapped() {
        if navigationController != nil {
            navigationController?.popViewController()
        } else {
            dismiss(animated: true)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of _: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = Float(webView.estimatedProgress)
            withUIKitAnimation(duration: 0.25) {
                self.progressBar.setProgress(progress, animated: progress >= 0.001)
            }
            if progress > 0.99 {
                withUIKitAnimation {
                    self.progressBar.alpha = 0.1
                }
            } else {
                withUIKitAnimation {
                    self.progressBar.alpha = 1
                }
            }
        }
    }
}
