//
//  TabBarController.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/30.
//

import Combine
import Source
import UIKit

class TabBarController: UITabBarController {
    weak var source: Source? = Account.shared.source
    var cancellable: Set<AnyCancellable> = []

    var previousSelection = 0

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.tintColor = .accent
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            // idx: 0
            Self.createTabPage(
                withImage: UIImage.fluent(.home_filled),
                withController: SmallTimelineController()
            ),
            // idx: 1
            Self.createTabPage(
                withImage: UIImage.fluent(.search_filled),
                withController: DiscoverSearchController()
            ),
            // idx: 2
            Self.createTabPage(
                withImage: UIImage.fluent(.person_filled),
                withController: CurrentUserViewController()
            ),
            // idx: 3
            Self.createTabPage(
                withImage: UIImage.fluent(.alert_filled),
                withController: SmallNotificationController()
            ),
            // idx: 4
            Self.createTabPage(
                withImage: UIImage.fluent(.settings_filled),
                withController: SettingController()
            ),
        ]

        let notificationIdx = 3
        source?.notifications.$badge
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                let tabItem = self?.tabBar.items?[safe: notificationIdx]
                tabItem?.badgeColor = .systemPink
                tabItem?.badgeValue = output > 0 ? String(output) : nil
            }
            .store(in: &cancellable)
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else {
            #if DEBUG
                fatalError("malformed application view tree")
            #else
                return
            #endif
        }
        if index != previousSelection {
            previousSelection = index
            if let viewRoot = item.value(forKey: "_view") as? UIView {
                shineTabButton(from: viewRoot)
            }
        } else {
            // scroll to top, has bug
            guard let controller = (viewControllers?[safe: index] as? UINavigationController)?
                .viewControllers
                .last
            else {
                return
            }
            // there is a bug, hiding stuff under the navigation title
            if let scrollView = controller.view as? UIScrollView {
                scrollView.setContentOffset(.init(x: 0, y: -topBarHeight - 50), animated: true)
            } else if let scrollView = controller
                .view
                .subviews
                .first as? UIScrollView
            {
                let tableView = scrollView as? UITableView
                tableView?.beginUpdates()
                scrollView.setContentOffset(.init(x: 0, y: -topBarHeight - 50), animated: true)
                tableView?.endUpdates()
            }
        }
    }

    func shineTabButton(from: UIView) {
        HapticGenerator.make(.light)
        if from is UIImageView {
            from.shineAnimation()
        } else {
            for view in from.subviews {
                shineTabButton(from: view)
            }
        }
    }

    private static func createTabPage(
        withImage icon: UIImage,
        withController controller: UIViewController
    ) -> UIViewController {
        let navigator = NoTitleNavController()
        navigator.platformSetup()
        navigator.viewControllers = [controller]
        navigator.navigationBar.prefersLargeTitles = false
        navigator.tabBarItem = .init(
            title: "", // title,
            image: icon,
            tag: (controller.title ?? UUID().uuidString).hashValue
        )
        return navigator
    }
}

private class NoTitleNavController: UINavigationController {
    override var title: String? {
        set {}
        get { nil }
    }
}
