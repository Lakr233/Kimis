//
//  LicenseController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/21.
//

import UIKit

class LicenseController: ViewController {
    let textView = TextView(editable: false, selectable: true, disableLink: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "License"

        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil),
           let str = try? String(contentsOfFile: url.path)
        {
            textView.text = str
        } else {
            textView.text = "License file unavailable, check git repo for details."
        }

        textView.textColor = .systemBlackAndWhite
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)

        textView.isScrollEnabled = true
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let padding = IH.preferredPadding(usingWidth: view.bounds.width)
        textView.textContainerInset = UIEdgeInsets(inset: padding)
    }
}
