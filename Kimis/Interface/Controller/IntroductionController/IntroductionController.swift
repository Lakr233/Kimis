//
//  IntroductionController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/10/31.
//

import MorphingLabel
import SnapKit
import UIKit

class IntroductionController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()

        isModalInPresentation = true

        // make it translucent but allow back button to show
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = .init()
        navigationBar.isTranslucent = true

        viewControllers = [WelcomeController()]
    }
}

private extension UIViewController {
    func disableNavTitle() {
        navigationItem.titleView?.isHidden = true
        navigationItem.titleView = UIView()
    }
}

private class NextButton: UIButton {
    enum Style {
        case accent
        case accentText
    }

    var style: Style = .accent {
        didSet { switchStyle() }
    }

    var tapped: (() -> Void)?

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 8
        titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        switchStyle()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    func switchStyle() {
        switch style {
        case .accent:
            setTitleColor(.accent, for: .normal)
            backgroundColor = .accent.withAlphaComponent(0.1)
        case .accentText:
            setTitleColor(.accent, for: .normal)
            backgroundColor = .gray.withAlphaComponent(0.1)
        }
    }

    func tapped(_ calling: @escaping () -> Void) {
        tapped = calling
    }

    @objc private func buttonTapped() {
        HapticGenerator.make(.light)
        tapped?()
    }
}

private class WelcomeStackController: ViewController {
    private let stackView = UIStackView()
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 20
        let views = viewsForStack()
        for view in views {
            let wrapper = UIView()
            wrapper.addSubview(view)
            view.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.height.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
            stackView.addArrangedSubview(wrapper)
        }
    }

    private var previousSize: CGSize = .zero
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if previousSize != view.frame.size {
            previousSize = view.frame.size
            updateStackFrame()
        }
    }

    func viewsForStack() -> [UIView] { [] }

    private let maxWidth: CGFloat = 650
    private let requiredPadding: CGFloat = 20
    func updateStackFrame() {
        var width = maxWidth
        if width > view.frame.width - requiredPadding * 2 {
            width = view.frame.width - requiredPadding * 2
        }
        stackView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
        }
    }
}

private class WelcomeController: WelcomeStackController {
    let nextController: UIViewController = FinalController()

    let nextButton: NextButton = .init()

    let mainImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "Introduction.Welcome")
        return view
    }()

    let mainTitle: UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isEditable = false
        view.text = "Welcome to Misskey"
        view.textColor = .systemBlackAndWhite
        view.font = .systemFont(ofSize: 24, weight: .semibold)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = true
        view.sizeToFit()
        view.isScrollEnabled = false
        return view
    }()

    let mainSubtitle: UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isEditable = false
        view.text = "Misskey is an open source, decentralized social media platform."
        view.font = .systemFont(ofSize: 16, weight: .regular)
        view.textColor = .systemBlackAndWhite.withAlphaComponent(0.75)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = true
        view.sizeToFit()
        view.isScrollEnabled = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Welcome"
        disableNavTitle()

        nextButton.setTitle("Next", for: .normal)
        nextButton.tapped {
            self.navigationController?.pushViewController(self.nextController, animated: true)
        }

        mainImage.snp.makeConstraints { x in
            x.height.equalTo(280)
            x.width.equalToSuperview().inset(20).priority(.low)
        }
        nextButton.snp.makeConstraints { x in
            x.width.equalTo(200)
            x.height.equalTo(50)
        }
    }

    override func viewsForStack() -> [UIView] {
        [
            mainImage,
            mainTitle,
            mainSubtitle,
            nextButton,
        ]
    }
}

private class FinalController: WelcomeStackController {
    let nextButton: NextButton = .init()

    let mainImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "Introduction.AllSet")
        view.tintColor = .accent
        return view
    }()

    let mainTitle: UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isEditable = false
        view.text = "You're all set!"
        view.textColor = .systemBlackAndWhite
        view.font = .systemFont(ofSize: 24, weight: .semibold)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = true
        view.sizeToFit()
        view.isScrollEnabled = false
        return view
    }()

    let mainSubtitle: UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isEditable = false
        view.text = "Initial setup completed! Congregations!"
        view.font = .systemFont(ofSize: 16, weight: .regular)
        view.textColor = .systemBlackAndWhite.withAlphaComponent(0.75)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = true
        view.sizeToFit()
        view.isScrollEnabled = false
        return view
    }()

    let confettiView: ConfettiView = {
        let view = ConfettiView()
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "All Set"
        disableNavTitle()

        view.addSubview(confettiView)
        confettiView.startConfetti()
        confettiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        nextButton.setTitle("Done", for: .normal)
        nextButton.tapped {
            AppConfig.current.introductionCompleted = true
            self.navigationController?.dismiss(animated: true)
        }

        mainImage.snp.makeConstraints { x in
            x.width.equalTo(80)
            x.height.equalTo(80)
        }
        nextButton.snp.makeConstraints { x in
            x.width.equalTo(200)
            x.height.equalTo(50)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        withUIKitAnimation {
            self.confettiView.alpha = 1
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        withUIKitAnimation {
            self.confettiView.alpha = 0
        }
    }

    override func viewsForStack() -> [UIView] {
        [
            mainImage,
            mainTitle,
            mainSubtitle,
            nextButton,
        ]
    }
}
