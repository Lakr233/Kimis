//
//  SmallNotificationController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

class SmallNotificationController: NotificationController {
    let indicator = UIActivityIndicatorView()
    let checker = UIButton()
    let rightBarView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        rightBarView.addSubview(indicator)
        rightBarView.addSubview(checker)

        checker.imageView?.contentMode = .scaleAspectFit
        checker.setImage(.fluent(.checkmark_filled), for: .normal)
        checker.addTarget(self, action: #selector(markNewestAsRead), for: .touchUpInside)
        checker.tintColor = .accent

        checker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        rightBarView.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(30).priority(.low)
        }
        navigationItem.rightBarButtonItem = .init(customView: rightBarView)

        source?.notifications.$updating
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    self?.startAnimating()
                } else {
                    self?.stopAnimating()
                }
            }
            .store(in: &tableView.cancellable)
    }

    func startAnimating() {
        checker.isHidden = true
        indicator.isHidden = false
        indicator.startAnimating()
    }

    func stopAnimating() {
        checker.isHidden = false
        indicator.isHidden = true
        indicator.stopAnimating()
    }
}
