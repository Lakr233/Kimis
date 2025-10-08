//
//  ProfileEditorController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Combine
import UIKit
import WebKit

class ProfileEditorController: UINavigationController {
    init() {
        super.init(rootViewController: _ProfileEditorController())

        prepareModalSheet(style: .formSheet)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()
    }
}

private class _ProfileEditorController: MisskeySafariController {
    override init() {
        super.init()
        title = L10n.text("Edit Profile")
    }

    override func load() {
        if let host = source?.host {
            let url = host
                .appendingPathComponent("settings")
                .appendingPathComponent("profile")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            webView.load(request)
        }
    }

    @objc override func doneTapped() {
        dismiss(animated: true)
        DispatchQueue.global().async {
            presentMessage(L10n.text("Updating Account Info"))
            self.source?.populateUserInfo(forceUpdate: true)
            presentMessage(L10n.text("Account Info Updated"))
        }
    }
}
