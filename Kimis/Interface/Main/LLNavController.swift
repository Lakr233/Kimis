//
//  LLNavController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import Combine
import GlyphixTextFx
import UIKit

// attach a customized view to the right of the navigation bar
protocol LLNavControllerAttachable {
    func determineTransparentRequest() -> Bool
    func determineAccentColor() -> UIColor?
    func determineTitleShouldShow() -> Bool

    func createRightBarView() -> UIView?
    func determineRightBarWidth() -> CGFloat?
}

extension LLNavControllerAttachable {
    func determineTransparentRequest() -> Bool { false }
    func determineAccentColor() -> UIColor? { nil }
    func determineTitleShouldShow() -> Bool { true }
    func createRightBarView() -> UIView? { nil }
    func determineRightBarWidth() -> CGFloat? { nil }
}

class LLNavController: ViewController, UINavigationControllerDelegate {
    let associatedNavigationController: UINavigationController

    var timer: Timer?

    init(rootViewController: UIViewController) {
        associatedNavigationController = .init(rootViewController: rootViewController)
        if let boundaryView = associatedNavigationController.view.subviews[safe: 0] {
            boundaryView.clipsToBounds = false
        } else {
            assertionFailure()
        }
        super.init(nibName: nil, bundle: nil)
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateAppearances()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    deinit {
        timer?.invalidate()
    }

    var viewControllers: [UIViewController] {
        associatedNavigationController.viewControllers
    }

    let blurBackground: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    let blurBackgroundColor: UIView = {
        let view = UIView()
        view.backgroundColor = .platformBackground
        return view
    }()

    let separator = UIView()

    let titleContainer: UIView = .init()

    let titleLabel: GlyphixTextLabel = {
        let view = GlyphixTextLabel()
        view.text = L10n.text("Misskey")
        view.textAlignment = .leading
        view.textColor = .systemBlackAndWhite
        view.font = .systemFont(ofSize: 20, weight: .semibold)
        return view
    }()

    @DefaultButton(icon: {
        let configure = UIImage.SymbolConfiguration(
            pointSize: 24,
            weight: .semibold
        )
        return UIImage(
            systemName: "arrow.left",
            withConfiguration: configure
        )
    }())
    var backButton: UIButton

    let dragableArea = UIView()

    let rightView = UIView()

    let titleLineHeight: CGFloat = 50
    var padding = IH.preferredViewPadding()

    override func viewDidLoad() {
        super.viewDidLoad()

        platformSetup()
        view.clipsToBounds = true

        addChildViewController(associatedNavigationController, toContainerView: view)
        associatedNavigationController.delegate = self
        associatedNavigationController.navigationBar.isHidden = true

        view.addSubview(blurBackgroundColor)
        view.addSubview(blurBackground)
        view.addSubview(titleContainer)
        view.addSubview(rightView)
        view.addSubview(separator)
        view.addSubview(dragableArea)
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(backButton)

        blurBackground.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(titleLineHeight)
        }
        blurBackgroundColor.snp.makeConstraints { make in
            make.edges.equalTo(blurBackground)
        }

        separator.backgroundColor = .separator
        separator.snp.makeConstraints { make in
            make.left.right.equalTo(blurBackground)
            make.top.equalTo(blurBackground.snp.bottom).offset(-0.5)
            // catalyst seems to have bug on 0.5 point of size
            make.height.equalTo(1)
        }

        titleContainer.snp.makeConstraints { make in
            make.edges.equalTo(blurBackground)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(backButton.snp.right)
            make.right.equalToSuperview()
        }

        rightView.clipsToBounds = true
        rightView.snp.makeConstraints { make in
            make.centerY.equalTo(backButton.snp.centerY)
            make.height.equalTo(titleLineHeight)
            make.right.equalTo(titleContainer.snp.right).offset(-padding)
            make.width.equalTo(0)
        }

        backButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(padding)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        backButton.alpha = 0
        backButton.imageView?.tintColor = .systemBlackAndWhite
        backButton.addTarget(self, action: #selector(popCurrent), for: .touchUpInside)
        backButton.isPointerInteractionEnabled = true

        associatedNavigationController.view.clipsToBounds = false
        associatedNavigationController.view.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separator.snp.bottom)
        }

        dragableArea.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right)
            make.top.equalToSuperview()
            make.bottom.equalTo(separator.snp.top)
            make.right.equalTo(rightView.snp.left)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        switch traitCollection.userInterfaceStyle {
        case .light: blurBackground.effect = UIBlurEffect(style: .regular)
        case .dark: blurBackground.effect = UIBlurEffect(style: .dark)
        case .unspecified: fallthrough
        @unknown default: blurBackground.alpha = 0
        }

        updateTitleHeight()
    }

    private var statusBarHeight: CGFloat = 0

    func updateTitleHeight() {
        let height = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        if statusBarHeight == height { return }
        statusBarHeight = height
        debugPrint("[UI] using status bar height \(height)")
        let fullHeight = titleLineHeight + height
        blurBackground.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(fullHeight)
        }
        titleContainer.snp.remakeConstraints { make in
            make.left.right.bottom.equalTo(blurBackground)
            make.top.equalToSuperview().inset(height)
        }
    }

    @objc func popCurrent() {
        guard viewControllers.count > 1 else {
            return
        }
        associatedNavigationController.popViewController(animated: true)
    }

    func navigationController(_: UINavigationController, willShow _: UIViewController, animated _: Bool) {
        blurBackgroundColor.alpha = 1
        updateAppearances()
    }

    func navigationController(_: UINavigationController, didShow _: UIViewController, animated _: Bool) {
        updateAppearances()
    }

    private let queue = DispatchQueue(label: "wiki.qaq.\(#file).updateAppearances")

    @objc func updateAppearances() {
        queue.async { self._updateAppearances() }
    }

    weak var previousViewController: UIViewController?

    struct LayoutRequest: Equatable {
        var title: String
        var transparentTitle: Bool
        var transparentBackground: Bool
        var accentColor: UIColor
        var backButtonWidth: CGFloat
        var titleInset: CGFloat

        static let defaultAppearance = LayoutRequest(
            title: "",
            transparentTitle: false,
            transparentBackground: false,
            accentColor: .systemBlackAndWhite,
            backButtonWidth: 0,
            titleInset: 0
        )
    }

    var currentLayoutRequest: LayoutRequest = .defaultAppearance

    private func _updateAppearances() {
        assert(!Thread.isMainThread)
        let sem = DispatchSemaphore(value: 0)
        withMainActor { [self] in
            if let boundaryView = associatedNavigationController.view.subviews[safe: 0] {
                if boundaryView.clipsToBounds { boundaryView.clipsToBounds = false }
            }

            guard let viewController = viewControllers.last else {
                assertionFailure()
                return
            }
            defer { previousViewController = viewController }

            // TODO: change padding based on NavController's width
            // padding = IH.preferredViewPadding(usingWidth: view.bounds.width)

            var request = LayoutRequest.defaultAppearance
            request.title = viewController.title ?? ""
            request.backButtonWidth = viewControllers.count > 1 ? 24 : 0
            request.titleInset = viewControllers.count > 1 ? padding : 0

            if previousViewController != viewController {
                rightView.removeSubviews()
            }

            if let attachable = viewController as? LLNavControllerAttachable {
                if previousViewController != viewController,
                   let view = attachable.createRightBarView(),
                   let width = attachable.determineRightBarWidth()
                {
                    rightView.removeSubviews()
                    rightView.addSubview(view)
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                    rightView.snp.updateConstraints { make in
                        make.width.equalTo(width)
                    }
                    UIView.performWithoutAnimation { view.layoutIfNeeded() }
                }

                request.transparentBackground = attachable.determineTransparentRequest()
                if let color = attachable.determineAccentColor() { request.accentColor = color }
                request.transparentTitle = !attachable.determineTitleShouldShow()
            }

            if blurBackgroundColor.alpha > 0 {
                withMainActor(delay: 0.5) {
                    withUIKitAnimation { self.blurBackgroundColor.alpha = 0 }
                }
            }

            layout(request: request) { sem.signal() }
        }
        sem.wait()
    }

    private func layout(request: LayoutRequest, completion: @escaping () -> Void) {
        assert(Thread.isMainThread)
        if request == currentLayoutRequest {
            completion()
            return
        }
        currentLayoutRequest = request
        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
        withUIKitAnimation { [self] in
            titleLabel.text = request.title
            titleLabel.alpha = request.transparentTitle ? 0 : 1
            blurBackground.alpha = request.transparentBackground ? 0 : 1
            separator.alpha = request.transparentBackground ? 0 : 1
            backButton.tintColor = request.accentColor
            titleLabel.textColor = request.accentColor
            backButton.isUserInteractionEnabled = request.backButtonWidth > 0
            backButton.isHidden = request.backButtonWidth <= 0
            backButton.alpha = request.backButtonWidth <= 0 ? 0 : 1
            backButton.snp.updateConstraints { make in
                make.width.equalTo(request.backButtonWidth)
            }
            titleLabel.snp.updateConstraints { make in
                make.left.equalTo(backButton.snp.right).offset(request.titleInset)
            }
            view.layoutIfNeeded()
        } completion: { completion() }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let key = press.key else { continue }
            if key.keyCode == .keyboardEscape {
                if associatedNavigationController.viewControllers.count > 1 {
                    didHandleEvent = true
                    associatedNavigationController.popViewController(animated: true)
                }
            }
        }
        if didHandleEvent == false {
            super.pressesBegan(presses, with: event)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if targetEnvironment(macCatalyst)
            if let loc = touches.first?.location(in: view),
               dragableArea.frame.contains(loc)
            {
                performMacCatalystWindowDrag()
            }
        #endif

        super.touchesBegan(touches, with: event)
    }
}

#if targetEnvironment(macCatalyst)
    private extension UIResponder {
        func performMacCatalystWindowDrag() {
            guard let nsApp = (
                (NSClassFromString("NSApplication") as? NSObject.Type)?
                    .value(forKey: "sharedApplication") as? NSObject
            ),
                let currentEvent = nsApp.value(forKey: "currentEvent") as? NSObject,
                let nsWindow = currentEvent.value(forKey: "window") as? NSObject
            else { return }
            nsWindow.perform(
                NSSelectorFromString("performWindowDragWithEvent:"),
                with: currentEvent
            )
        }
    }
#endif
