//
//  SearchController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Combine
import UIKit

class SearchController: ViewController {
    let icon = UIImageView()
    let searchBarContainer = UIView()
    let searchBar = UISearchBar()
    let circle = UIView()
    let arrow = UIImageView()
    @DefaultButton
    var searchButton: UIButton

    let searchDelegate = SearchDelegate()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = L10n.text("Search")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchDelegate.anchor = view
        searchBar.delegate = searchDelegate

        let spacing: CGFloat = 20

        #if targetEnvironment(macCatalyst)
            searchBarContainer.backgroundColor = .accent.withAlphaComponent(0.1)
        #endif
        view.addSubview(searchBarContainer)
        searchBarContainer.addSubview(searchBar)
        searchBarContainer.layer.cornerRadius = IH.contentCornerRadius
        searchBarContainer.clipsToBounds = true

        searchBar.placeholder = L10n.text("Search Anything")
        searchBar.backgroundColor = .clear
        searchBar.backgroundImage = .init()
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
                .inset(UIEdgeInsets(inset: -2))
        }

        icon.image = UIImage(named: "AppAvatar")
        icon.contentMode = .scaleAspectFit
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalTo(searchBarContainer.snp.centerX)
            make.width.height.equalTo(64)
            make.bottom.equalTo(searchBarContainer.snp.top).offset(-spacing)
        }

        circle.backgroundColor = .accent.withAlphaComponent(0.1)
        view.addSubview(circle)
        circle.snp.makeConstraints { make in
            make.centerX.equalTo(searchBarContainer.snp.centerX)
            make.width.height.equalTo(40)
            make.top.equalTo(searchBarContainer.snp.bottom).offset(spacing)
        }

        arrow.image = UIImage(systemName: "arrow.right")
        arrow.tintColor = .accent
        arrow.contentMode = .scaleAspectFit
        circle.addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalToSuperview()
        }

        view.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.edges.equalTo(circle)
        }
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        view.layoutIfNeeded()

        let bounds = view.bounds
        let padding = IH.preferredPadding(usingWidth: bounds.width)
        let searchBarWidth = IH.containerWidth(
            usingWidth: bounds.width - 2 * padding,
            maxWidth: 500
        )
        searchBarContainer.frame = CGRect(
            center: bounds.center,
            size: CGSize(
                width: searchBarWidth,
                height: searchBar.intrinsicContentSize.height
            )
        )

        circle.layer.cornerRadius = circle.frame.width / 2
    }

    @objc func searchButtonTapped() {
        searchDelegate.finalizeSearchRequest(text: searchBar.text)
    }
}
