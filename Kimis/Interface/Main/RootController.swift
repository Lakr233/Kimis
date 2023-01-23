//
//  ViewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import Combine
import UIKit

private struct SetupElement {
    let controller: () -> (UIViewController)
    let condition: () -> (Bool)
}

private let setupControllers: [SetupElement] = [
    .init(controller: {
        IntroductionController()
    }, condition: {
        !AppConfig.current.introductionCompleted
    }),
    .init(controller: {
        LoginController()
    }, condition: {
        Account.shared.loginRequested
    }),
]

class RootController: ViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        Account.shared.$source
            .receive(on: DispatchQueue.main)
            .map { [weak self] value in
                self?.controller = LoadingController()
                self?.smallController = nil
                self?.largeController = nil
                return value
            }
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.buildContentController(forceReload: true)
                    self?.presentSetupControllersIfNeeded()
                }
            }
            .store(in: &cancellable)
    }

    private var _controller: UIViewController?

    var controller: UIViewController? {
        set {
            if let _controller {
                _controller.willMove(toParent: nil)
                _controller.view.removeFromSuperview()
                _controller.removeFromParent()
            }
            _controller = nil
            if let newValue {
                _controller = newValue
                addChildViewController(newValue, toContainerView: view)
            }
            controller?.view.setNeedsLayout()
            view.setNeedsLayout()
        }
        get { _controller }
    }

    @objc private func switchedAccount() {
        withMainActor {
            self.controller = nil
            self.buildContentController(forceReload: true)
            self.presentSetupControllersIfNeeded()
        }
    }

    var currentSize: CGSize = .init(width: 0, height: 0)
    var previousLayoutSize: CGSize = .init()

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        controller?.view.frame = view.bounds
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        buildContentController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        controller = LoadingController()
        buildContentController()
        presentSetupControllersIfNeeded()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let key = press.key else { continue }
            if key.keyCode == .keyboardN, key.modifierFlags.contains(.command) {
                ControllerRouting.pushing(tag: .post, referencer: view)
                didHandleEvent = true
            }
        }
        if didHandleEvent == false {
            super.pressesBegan(presses, with: event)
        }
    }

    func buildContentController(forceReload: Bool = false) {
        assert(Thread.isMainThread)
        if !forceReload, previousLayoutSize == view.frame.size { return }
        print("[UI] layout size changed from \(previousLayoutSize) to \(view.frame.size)")
        previousLayoutSize = view.frame.size
        loadController()
    }

    private var largeController: SideBarController?
    private var smallController: TabBarController?

    /*
     Layout Size may change when enter background on iPads
     providing misleading info that will lose user focus

     [UI] layout size changed from (834.0, 1194.0) to (592.0, 834.0)
     [UI] using status bar height 0.0
     /Users/qaq/Documents/GitLab/Kimis/Kimis/Interface/Main/SideBarController.swift deinit
     [UI] layout size changed from (592.0, 834.0) to (1194.0, 834.0)
     */

    func loadController() {
        if Account.shared.source == nil {
            controller = LoadingController()
            return
        }
        if shouldUseLargeUI() {
            if controller?.isKind(of: SideBarController.self) ?? false { } else {
                if let large = largeController {
                    controller = large
                } else {
                    let c = SideBarController()
                    controller = c
                    largeController = c
                }
            }
        } else {
            if controller?.isKind(of: TabBarController.self) ?? false { } else {
                if let small = smallController {
                    controller = small
                } else {
                    let c = TabBarController()
                    controller = c
                    smallController = c
                }
            }
        }
    }

    func shouldUseLargeUI() -> Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            let currentIdiom = UIDevice.current.userInterfaceIdiom
            if #available(iOS 14.0, *) {
                if !(currentIdiom == .pad || currentIdiom == .mac) {
                    return false
                }
            } else {
                if !(currentIdiom == .pad) {
                    return false
                }
            }
            if !(view.frame.width > 600 && view.frame.height > 400) {
                return false
            }
            return true
        #endif
    }

    func presentSetupControllersIfNeeded() {
        if presentedViewController != nil { return }

        var targetController: UIViewController?
        search: for element in setupControllers {
            if element.condition() {
                targetController = element.controller()
                break search
            }
        }
        guard let controller = targetController else {
            return
        }
        #if targetEnvironment(macCatalyst)
            controller.prepareModalSheet(style: .fullScreen)
        #else
            controller.prepareModalSheet()
        #endif
        present(controller, animated: true)
        monitorOverViewController(target: controller) {
            self.presentSetupControllersIfNeeded()
        }
    }

    func monitorOverViewController(target: UIViewController, onDismiss: @escaping () -> Void) {
        DispatchQueue.global().async {
            var continueWait = true
            while continueWait {
                usleep(100_000)
                let sem = DispatchSemaphore(value: 0)
                withMainActor {
                    continueWait = target.isVisible || target.isBeingPresented || target.isBeingDismissed
                    sem.signal()
                }
                sem.wait()
            }
            withMainActor { onDismiss() }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
