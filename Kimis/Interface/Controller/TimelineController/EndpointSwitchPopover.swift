//
//  EndpointSwitchPopover.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/6.
//

import Combine
import Source
import UIKit

class EndpointSwitchPopover: ViewController, UIPopoverPresentationControllerDelegate {
    let contentView = UIView()

    init(sourceView: UIView) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        preferredContentSize = CGSize(width: 400, height: 400)
        popoverPresentationController?.delegate = self
        popoverPresentationController?.sourceView = sourceView
        let padding: CGFloat = 4
        popoverPresentationController?.sourceRect = .init(
            x: -padding,
            y: -padding,
            width: sourceView.frame.width + padding * 2,
            height: sourceView.frame.height + padding * 2
        )
        popoverPresentationController?.permittedArrowDirections = .any
        view.addSubview(contentView)
    }

    let titleLabel = UILabel(text: "👉\nSwitch Endpoint")
    let stackView = UIStackView()

    let inset = UIEdgeInsets(inset: 14)

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }
        stackView.axis = .vertical
        stackView.addArrangedSubviews(TimelineSource.Endpoint.allCases.map { createView(forCase: $0) })
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
    }

    func createView(forCase: TimelineSource.Endpoint) -> UIView {
        Cell(forCase, isActivated: source?.timeline.sourceEndpoint == forCase)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func adaptivePresentationStyle(
        for _: UIPresentationController,
        traitCollection _: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        contentView.snp.remakeConstraints { x in
            x.left.right.equalToSuperview()
            x.centerY.equalToSuperview()
        }
    }
}

extension EndpointSwitchPopover {
    class Cell: UIView {
        static let inset: CGFloat = 10
        weak var source: Source? = Account.shared.source

        let mainIcon = UIImageView()
        let mainLabel = UILabel()
        let explanationLabel = UILabel()
        let button = UIButton()
        let endpoint: TimelineSource.Endpoint

        init(_ endpoint: TimelineSource.Endpoint, isActivated: Bool) {
            self.endpoint = endpoint
            super.init(frame: .zero)
            addSubview(mainIcon)
            mainLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            mainLabel.numberOfLines = 0
            mainLabel.textColor = .systemBlackAndWhite
            addSubview(mainLabel)
            explanationLabel.font = .systemFont(ofSize: 14, weight: .regular)
            explanationLabel.numberOfLines = 0
            explanationLabel.textColor = .systemBlackAndWhite.withAlphaComponent(0.5)
            addSubview(explanationLabel)
            mainIcon.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(Self.inset * 2)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
            }
            mainLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Self.inset)
                make.left.equalTo(mainIcon.snp.right).offset(Self.inset)
                make.right.equalToSuperview().offset(-Self.inset * 2)
            }
            explanationLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-Self.inset)
                make.left.equalTo(mainLabel)
                make.right.equalTo(mainLabel)
                make.top.equalTo(mainLabel.snp.bottom).offset(2)
            }
            mainIcon.tintColor = isActivated ? .accent : .gray
            mainIcon.image = endpoint.representedIcon
            mainLabel.text = endpoint.title
            explanationLabel.text = endpoint.explanation

            addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            button.addTarget(self, action: #selector(performSwitch), for: .touchUpInside)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func performSwitch() {
            button.backgroundColor = .gray.withAlphaComponent(0.5)
            withUIKitAnimation {
                self.button.backgroundColor = .clear
                self.parentViewController?.dismiss(animated: true)
            }
            DispatchQueue.global().async {
                self.source?.timeline.activate(endpoint: self.endpoint)
            }
        }
    }
}

extension EndpointSwitchPopover {
    class OpeningButton: UIButton {
        weak var source: Source? = Account.shared.source
        private var cancellables: Set<AnyCancellable> = []

        init() {
            super.init(frame: .zero)
            defaultButton()
            addTarget(self, action: #selector(openEndpointSelector), for: .touchUpInside)
            setTitleColor(.accent, for: .normal)
            tintColor = .accent
            source?.timeline.$sourceEndpoint
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] value in
                    self?.loadEndpointIcon(endpoint: value)
                }
                .store(in: &cancellables)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func openEndpointSelector() {
            let controller = EndpointSwitchPopover(sourceView: self)
            window?.topController?.present(controller, animated: true)
        }

        func loadEndpointIcon(endpoint: TimelineSource.Endpoint) {
            setImage(endpoint.representedIcon, for: .normal)
        }
    }
}

private extension TimelineSource.Endpoint {
    var representedIcon: UIImage {
        switch self {
        case .home: return .fluent(.reading_list_filled)
        case .local: return .fluent(.city_filled)
        case .hybrid: return .fluent(.cloud_swap_filled)
        case .global: return .fluent(.gantt_chart_filled)
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .local: return "Local"
        case .hybrid: return "Hybrid"
        case .global: return "Global"
        }
    }

    var explanation: String {
        switch self {
        case .home: return "Your main timeline at a glance, with posts from the people you follow."
        case .local: return "Notes on your server."
        case .hybrid: return "Notes on local and remote servers."
        case .global: return "Everything you need to know about everything."
        }
    }
}
