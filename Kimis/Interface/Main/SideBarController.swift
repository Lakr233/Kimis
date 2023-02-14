//
//  SideBarController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/8.
//

import UIKit

class SideBarController: ViewController, UINavigationControllerDelegate {
    private let controlPanel: SideBarControlPanelView
    private var _contentController: UIViewController
    var contentController: UIViewController {
        set {
            _contentController.removeViewAndControllerFromParentViewController()
            _contentController = newValue
            addChildViewController(newValue, toContainerView: view)
            newValue.view.snp.remakeConstraints { make in
                make.top.right.bottom.equalToSuperview()
                make.left.equalTo(controlPanel.snp.right)
            }
        }
        get { _contentController }
    }

    init() {
        controlPanel = .init()
        let controller: UIViewController
        if let first = controlPanel.controlList.first {
            controller = first.controller
        } else {
            assertionFailure()
            controller = .init()
        }
        _contentController = controller
        super.init(nibName: nil, bundle: nil)
        // do the setup
        contentController = controller
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        #if DEBUG
            print("\(#file) \(#function)")
        #endif
        controlPanel.parent = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()

        view.addSubview(controlPanel)
        addChildViewController(contentController, toContainerView: view)

        controlPanel.parent = self
        controlPanel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            #if targetEnvironment(macCatalyst)
                make.width.equalTo(88)
            #else
                make.width.equalTo(78)
            #endif
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.setNeedsLayout()
    }
}

private class SideBarControlPanelView: UIView {
    let controlList: [SideBarControlPanelView.PanelButton]

    var highLightIndex: Int = -1 {
        didSet {
            controlList.forEach { $0.displaying.tintColor = .systemBlackAndWhite.withAlphaComponent(0.5) }
            guard let item = controlList[safe: highLightIndex] else {
                return
            }
            item.displaying.tintColor = .accent
        }
    }

    weak var parent: SideBarController?

    let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 6
        return view
    }()

    let container: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    let postButton = PostButton()

    init() {
        controlList = [
            .init(
                target: { LLSplitController(
                    left: LLNavController(rootViewController: LargeTimelineController()),
                    right: LLNavController(rootViewController: HashtagTrendController())
                ) },
                image: .fluent(.home_filled)
            ),
            .init(
                target: { LLSplitController(
                    left: LLNavController(rootViewController: SearchController()),
                    right: LLNavController(rootViewController: LargeUsersListController())
                ) },
                image: .fluent(.search_filled)
            ),
            .init(
                target: { LLSplitController(
                    left: LLNavController(rootViewController: LargeNotificationController()),
                    right: LLNavController(rootViewController: HashtagTrendController())
                ) },
                image: .fluent(.alert_filled)
            ),
            .init(
                target: { LLSplitController(
                    left: LLNavController(rootViewController: BookmarkController()),
                    right: LLNavController(rootViewController: HashtagTrendController())
                ) },
                image: .fluent(.bookmark_filled)
            ),
            .init(
                target: { LLSplitController(
                    left: LLNavController(rootViewController: CurrentUserViewController()),
                    right: LLNavController(rootViewController: HashtagTrendController())
                ) },
                displayingView: AccountAvatarView()
            ),
            .init(
                target: { LLNavController(rootViewController: SettingController()) },
                image: .fluent(.settings_filled)
            ),
        ]
        super.init(frame: .zero)
        backgroundColor = .accent.withAlphaComponent(0.05)
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        container.addSubview(stackView)
        #if targetEnvironment(macCatalyst)
            let topSpacer = UIView(frame: .zero)
            stackView.addArrangedSubview(topSpacer)
            topSpacer.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
            stackView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        #else
            stackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        #endif
        addSubview(postButton)
        postButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.height.equalTo(postButton.snp.width)
            #if targetEnvironment(macCatalyst)
                make.width.equalTo(self).inset(20)
                make.bottom.equalTo(self).inset(20)
            #else
                make.width.equalTo(self).inset(16)
                make.bottom.equalTo(self).inset(16)
            #endif
        }
        for button in controlList {
            button.button.addTarget(self, action: #selector(buttonTouched(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        // didSet will not work inside init
        withMainActor { self.highLightIndex = 0 }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    #if DEBUG
        var flexCount = 0
    #endif

    @objc func buttonTouched(_ sender: Any) {
        guard let sender = sender as? UIView,
              let button = sender.superview as? PanelButton,
              let parent
        else {
            assertionFailure()
            return
        }
        UIView.setAnimationsEnabled(false)
        defer { withMainActor(delay: 0.5) {
            // 防止 table view 因为窗口大小改变突然弄的很难看
            UIView.setAnimationsEnabled(true)
        } }
        button.displaying.shineAnimation()
        if parent.contentController == button.controller {
            let lookup: UIViewController = parent.contentController

            if let split = lookup as? LLSplitController,
               let nav = split.leftController as? LLNavController
            {
                nav.associatedNavigationController.popToRootViewController(animated: true)
            } else if let nav = lookup as? LLNavController {
                nav.associatedNavigationController.popToRootViewController(animated: true)
            } else if let nav = lookup as? UINavigationController {
                nav.popToRootViewController(animated: true)
            }
        } else {
            parent.contentController = button.controller
        }
        highLightIndex = controlList.firstIndex(of: button) ?? -1
    }
}

private extension SideBarControlPanelView {
    class PanelButton: UIView {
        private var controllerCache: UIViewController?
        var controller: UIViewController {
            assert(Thread.isMainThread)
            if let cache = controllerCache {
                return cache
            } else {
                let cache = target()
                controllerCache = cache
                return cache
            }
        }

        let target: () -> (UIViewController)
        @DefaultButton
        var button: UIButton
        let displaying: UIView

        convenience init(target: @escaping () -> (UIViewController), image: UIImage) {
            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            self.init(target: target, displayingView: imageView)
        }

        init(target: @escaping () -> (UIViewController), displayingView: UIView) {
            self.target = target
            displaying = displayingView
            super.init(frame: .zero)
            addSubview(displaying)
            addSubview(button)
            displaying.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(24)
                make.height.equalTo(24)
            }
            displaying.tintColor = .gray
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            snp.makeConstraints { make in
                make.width.equalTo(50)
                make.height.equalTo(50)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }
    }
}
