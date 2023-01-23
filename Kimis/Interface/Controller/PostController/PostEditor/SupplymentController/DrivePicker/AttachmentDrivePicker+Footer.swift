//
//  AttachmentDrivePicker.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/9.
//

import Combine
import Source
import UIKit

extension AttachmentDrivePicker {
    class LoadMoreFooterButton: UICollectionReusableView {
        static let cellId = "FooterView"
        static let buttonSize = CGSize(width: 233, height: 50)

        let button = UIButton()
        let indicator = UIActivityIndicatorView()

        weak var picker: AttachmentDrivePicker? {
            didSet { if let picker {
                picker.$loading
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] output in
                        if output {
                            self?.startAnimating()
                        } else {
                            self?.stopAnimating()
                        }
                    }
                    .store(in: &picker.cancellable)
            } }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            button.layer.cornerRadius = IH.contentCornerRadius
            button.backgroundColor = .accent.withAlphaComponent(0.1)
            addSubview(button)
            button.setTitle("Load More", for: .normal)
            button.setTitleColor(.accent, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(Self.buttonSize.width)
                make.height.equalTo(Self.buttonSize.height)
            }

            addSubview(indicator)
            indicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        @objc func buttonTapped() {
            guard let picker else { return }
            picker.loadMore()
        }

        func startAnimating() {
            button.alpha = 0
            indicator.startAnimating()
        }

        func stopAnimating() {
            button.alpha = 1
            indicator.stopAnimating()
        }
    }
}
