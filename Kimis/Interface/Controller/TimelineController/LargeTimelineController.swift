//
//  LargeTimelineController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/6.
//

import Combine
import UIKit

class LargeTimelineController: TimelineController, LLNavControllerAttachable {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = .init(top: -1, left: 0, bottom: 100, right: 0)
    }

    let barView = RightBarView()

    func createRightBarView() -> UIView? {
        barView
    }

    func determineRightBarWidth() -> CGFloat? {
        barView.estimatedWidth
    }
}

extension LargeTimelineController {
    class RightBarView: UIView {
        let estimatedWidth: CGFloat = 100

        weak var source: Source? = Account.shared.source
        private var cancellables: Set<AnyCancellable> = []

        let activityIndicator = UIActivityIndicatorView()
        let endpointSwitchView = EndpointSwitchPopover.OpeningButton()

        init() {
            super.init(frame: .zero)
            addSubview(activityIndicator)
            addSubview(endpointSwitchView)

            endpointSwitchView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview()
                make.width.equalTo(30)
                make.height.equalTo(30)
            }
            activityIndicator.snp.makeConstraints { make in
                make.right.equalTo(endpointSwitchView.snp.left).offset(-10)
                make.centerY.equalToSuperview()
            }

            source?.timeline.$updating
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] value in
                    self?.fetcherStatusChanged(updating: value)
                }
                .store(in: &cancellables)
        }

        func fetcherStatusChanged(updating: Bool) {
            if updating {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
