//
//  DiscoverSearchController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

// only available at small interface style

class DiscoverSearchController: ViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    let searchController = UISearchController()
    let searchDelegate = SearchDelegate()

    struct DiscoverSection {
        struct Element {
            let title: String
            let icon: String
            let action: (_ anchor: UIViewController) -> Void
        }

        let title: String
        let elements: [Element]
    }

    static let sections: [DiscoverSection] = [
        .init(title: "Collections", elements: [
            .init(title: "Bookmark", icon: "bookmark.fill", action: { anchor in
                if let nav = anchor.navigationController {
                    nav.pushViewController(BookmarkController(), animated: true)
                } else {
                    anchor.present(next: BookmarkController())
                }
            }),
        ]),
        .init(title: "Trending", elements: [
            .init(title: "Popular Hashtags", icon: "number", action: { anchor in
                if let nav = anchor.navigationController {
                    nav.pushViewController(HashtagTrendController(), animated: true)
                } else {
                    anchor.present(next: HashtagTrendController())
                }
            }),
            .init(title: "Popular Users", icon: "person.2.fill", action: { anchor in
                if let nav = anchor.navigationController {
                    nav.pushViewController(SmallUseresListController(), animated: true)
                } else {
                    anchor.present(next: SmallUseresListController())
                }
            }),
        ]),
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Discover"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self

//        searchController.platformSetup()
        searchDelegate.anchor = view
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = searchDelegate
    }
}

extension DiscoverSearchController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        Self.sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.sections[safe: section]?.elements.count ?? 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if let element = Self.sections[safe: indexPath.section]?.elements[safe: indexPath.row] {
            cell.imageView?.contentMode = .scaleAspectFit
            cell.imageView?.image = UIImage(systemName: element.icon)?
                .sd_resizedImage(with: CGSize(width: 24, height: 24), scaleMode: .aspectFit)?
                .withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = .accent
            cell.textLabel?.text = element.title
        }
        return cell
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        Self.sections[safe: section]?.title
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let element = Self.sections[safe: indexPath.section]?.elements[safe: indexPath.row] {
            element.action(self)
        }
    }
}
