//
//  SmallTimelineController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/6.
//

import Combine
import UIKit

class SmallTimelineController: TimelineController {
    let postButton = PostButton()

    let navigationBarRightItemView = UIView()
    let loadingIndicator = UIActivityIndicatorView()
    let popoverButton = EndpointSwitchPopover.OpeningButton()
    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBarRightItemView.addSubview(loadingIndicator)
        navigationBarRightItemView.addSubview(popoverButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationBarRightItemView)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        popoverButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        navigationBarRightItemView.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(30).priority(.low)
        }

        view.addSubview(postButton)
        postButton.dropShadow(ofColor: .black, radius: 4, offset: .zero, opacity: 0.1)

        source?.timeline.$updating
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.fetcherStatusChanged(updating: value)
            }
            .store(in: &cancellables)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let bounds = view.bounds
        let postButtonSize = CGSize(width: 62, height: 62)
        let postButtonPadding: CGFloat = 12
        postButton.frame = CGRect(
            x: bounds.width - postButtonSize.width - postButtonPadding - view.safeAreaInsets.right,
            y: bounds.height - postButtonSize.height - postButtonPadding - view.safeAreaInsets.bottom,
            width: postButtonSize.width,
            height: postButtonSize.height,
        )
    }

    func fetcherStatusChanged(updating: Bool) {
        if updating {
            loadingIndicator.startAnimating()
            popoverButton.isHidden = true
        } else {
            loadingIndicator.stopAnimating()
            popoverButton.isHidden = false
        }
    }
}
