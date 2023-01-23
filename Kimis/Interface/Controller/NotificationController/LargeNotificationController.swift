//
//  LargeNotificationController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

class LargeNotificationController: NotificationController, LLNavControllerAttachable {
    let indicator = UIActivityIndicatorView()
    let checker = UIButton()
    let barView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = .init(top: -1, left: 0, bottom: 0, right: 0)

        barView.addSubview(indicator)
        barView.addSubview(checker)

        checker.imageView?.contentMode = .scaleAspectFit
        checker.setImage(.fluent(.checkmark_filled), for: .normal)
        checker.addTarget(self, action: #selector(markNewestAsRead), for: .touchUpInside)
        checker.tintColor = .accent

        checker.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(30)
        }

        indicator.snp.makeConstraints { make in
            make.right.equalTo(checker.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }

        source?.notifications.$updating
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
            }
            .store(in: &tableView.cancellable)
    }

    func determineRightBarWidth() -> CGFloat? {
        100
    }

    func createRightBarView() -> UIView? {
        barView
    }
}
