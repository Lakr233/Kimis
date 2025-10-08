//
//  SettingController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import SDWebImage
import UIKit

private let sourceUrl = URL(string: "https://github.com/Lakr233/Kimis")!
private let issueUrl = URL(string: "https://github.com/Lakr233/Kimis/issues")!

private struct Thanks {
    let name: String
    let url: URL?
}

private let thanks: [Thanks] = [
    .init(
        name: "@Lakr233 @twitter.com",
        url: URL(string: "https://twitter.com/Lakr233")
    ),
    .init(
        name: "@Lakr233 @github.com",
        url: URL(string: "https://github.com/Lakr233")
    ),
    .init(
        name: "@unixzii @twitter.com",
        url: URL(string: "https://twitter.com/unixzii")
    ),
    .init(
        name: "@NekoyueW @twitter.com",
        url: URL(string: "https://twitter.com/NekoyueW")
    ),
]

class SettingController: ViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    var sections = [TableSection]() {
        didSet { tableView.reloadData() }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = L10n.text("Setting")
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
        #if targetEnvironment(macCatalyst)
            tableView.backgroundView = nil
            tableView.backgroundColor = .systemGray.withAlphaComponent(0.05)
        #endif

        prepareNewDataSource()
    }

    func resetPublishers() {
        cancellable.forEach { $0.cancel() }
        cancellable = []

        Account.shared.$updated
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetPublishers()
                self?.prepareNewDataSource()
            }
            .store(in: &cancellable)

        Account.shared.source?.$user
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.prepareNewDataSource()
            }
            .store(in: &cancellable)

        Account.shared.source?.$instance
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.prepareNewDataSource()
            }
            .store(in: &cancellable)
    }

    func prepareNewDataSource() {
        var result = [TableSection]()
        result.append(.init(title: L10n.text("Account"), elements: [
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = Account.shared.source?.user.absoluteUsername
                return cell
            } action: { _ in
                UIPasteboard.general.string = Account.shared.source?.user.absoluteUsername
                presentMessage(L10n.text("Copied"))
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let unknown = L10n.text("Unknown")
                cell.textLabel?.text = L10n.text("%@", Account.shared.source?.user.userId ?? unknown)
                return cell
            } action: { _ in
                UIPasteboard.general.string = Account.shared.source?.user.userId
                presentMessage(L10n.text("Copied"))
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Sign Out")
                cell.textLabel?.textColor = .systemPink
                return cell
            } action: { tableView in
                let alert = UIAlertController(title: "⚠️", message: L10n.text("Are you sure you want to sign out?"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.text("Sign Out"), style: .destructive) { _ in
                    if let id = Account.shared.source?.receiptId {
                        Account.shared.delete(receiptID: id)
                    }
                    Account.shared.deactivateCurrent()
                })
                alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
                tableView.parentViewController?.present(alert, animated: true)
            },
        ]))
        result.append(.init(title: L10n.text("Instance"), elements: [
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = Account.shared.source?.instance.name
                return cell
            } action: { _ in
                UIPasteboard.general.string = Account.shared.source?.instance.name
                presentMessage(L10n.text("Copied"))
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let unknown = L10n.text("Unknown")
                cell.textLabel?.text = L10n.text("Version: %@", Account.shared.source?.instance.version ?? unknown)
                return cell
            } action: { _ in
                UIPasteboard.general.string = Account.shared.source?.instance.version
                presentMessage(L10n.text("Copied"))
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Contact Maintainer")
                cell.textLabel?.textColor = .accent
                return cell
            } action: { _ in
                guard let str = Account.shared.source?.instance.maintainerEmail,
                      str.isValidEmail,
                      let url = URL(string: "mailto:\(str)")
                else {
                    presentError(L10n.text("Not available on this instance"))
                    return
                }
                UIApplication.shared.open(url)
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Open Instance's Policy")
                cell.textLabel?.textColor = .accent
                return cell
            } action: { _ in
                guard let str = Account.shared.source?.instance.tosUrl,
                      let url = URL(string: str),
                      url.scheme?.lowercased().hasPrefix("http") ?? false
                else {
                    presentError(L10n.text("Not available on this instance"))
                    return
                }
                UIApplication.shared.open(url)
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Update Metadata")
                cell.textLabel?.textColor = .accent
                return cell
            } action: { _ in
                presentMessage(L10n.text("Updating Instance Metadata"))
                DispatchQueue.global().async {
                    Account.shared.source?.populateInstanceInfo(forceUpdate: true)
                    presentMessage(L10n.text("Instance Metadata Updated"))
                }
            },
        ]))
        result.append(.init(title: L10n.text("Application"), elements: [
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("App Version: %@", appVersion)
                return cell
            } action: { _ in
                UIPasteboard.general.string = appVersion
                presentMessage(L10n.text("Copied"))
            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("License")
                cell.textLabel?.textColor = .accent
                return cell
            } action: { tableView in
                if let nav = tableView.parentViewController?.navigationController {
                    nav.pushViewController(LicenseController())
                } else {
                    tableView.parentViewController?.present(LicenseController(), animated: true)
                }
            },
            .init(configure: {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Get Source Code")
                cell.textLabel?.textColor = .accent
                return cell
            }, action: { _ in
                UIApplication.shared.open(sourceUrl)
            }),
            .init(configure: {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Report Problem")
                cell.textLabel?.textColor = .accent
                return cell
            }, action: { _ in
                UIApplication.shared.open(issueUrl)
            }),
        ]))
        result.append(.init(title: L10n.text("Misc"), elements: [
            //            .init {
//                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
//                cell.textLabel?.text = "Access In Browser"
//                cell.textLabel?.textColor = .accent
//                return cell
//            } action: { tableView in
//                if let nav = tableView.parentViewController?.navigationController {
//                    nav.pushViewController(MisskeySafariController())
//                } else {
//                    tableView.parentViewController?.present(MisskeySafariController(), animated: true)
//                }
//            },
            .init {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = L10n.text("Clear Cache")
                cell.textLabel?.textColor = .accent
                return cell
            } action: { _ in
                SDImageCache.shared.clearMemory()
                SDImageCache.shared.clearDisk()
                try? FileManager.default.removeItem(at: temporaryDirectory)
                try? FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
                presentMessage(L10n.text("Cache Cleared"))
            },
        ]))
        result.append(.init(title: L10n.text("Thanks"), elements:
            thanks.map { item -> TableSection.TableElement in
                .init {
                    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                    cell.textLabel?.text = item.name
                    return cell
                } action: { anchor in
                    if let url = item.url {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            ControllerRouting.pushing(deepLink: url.absoluteString, referencer: anchor)
                        }
                    }
                }

            }))
        sections = result
    }
}

extension SettingController {
    struct TableSection {
        let title: String?
        let elements: [TableElement]
        struct TableElement {
            let configure: () -> (UITableViewCell)
            let action: (_ tableView: UITableView) -> Void
        }
    }
}

extension SettingController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[safe: section]?.elements.count ?? 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        sections[safe: indexPath.section]?
            .elements[safe: indexPath.row]?
            .configure()
            ?? .init(style: .default, reuseIdentifier: nil)
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[safe: section]?.title
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[safe: indexPath.section]?
            .elements[safe: indexPath.row]?
            .action(tableView)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
