//
//  LoginController.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/31.
//

import SafariServices
import SnapKit
import Source
import UIKit

private let kTextFieldMaxWidth: CGFloat = 550

class LoginController: UINavigationController {
    init() {
        super.init(rootViewController: RealLoginController())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class RealLoginController: ViewController, UITextFieldDelegate {
    let icon: UIView = {
        let ret = UIImageView()
        ret.image = UIImage(named: "Login.Account")
        ret.tintColor = .accent
        ret.contentMode = .scaleAspectFit
        return ret
    }()

    let labelWelcome: UILabel = {
        let ret = UILabel()
        ret.text = L10n.text("Login")
        ret.textAlignment = .center
        ret.font = .systemFont(ofSize: 24, weight: .semibold)
        ret.textColor = UIColor(light: .black, dark: .white)
        return ret
    }()

    let textFieldInputHost: UITextField = {
        let ret = PaddedTextField()
        ret.backgroundColor = .accent.withAlphaComponent(0.1)
        ret.autocapitalizationType = .none
        ret.autocorrectionType = .no
        ret.textContentType = .URL
        ret.placeholder = L10n.text("[Host] eg: misskey.io (not username)")
        ret.textColor = .accent
        ret.returnKeyType = .done
        ret.layer.cornerRadius = 8
        ret.font = .rounded(ofSize: 16, weight: .medium)
        return ret
    }()

    let labelLoginHint: UILabel = {
        let ret = UILabel()
        ret.text = L10n.text("Host Address")
        ret.textColor = .gray
        ret.font = .systemFont(ofSize: 16, weight: .semibold)
        ret.textAlignment = .left
        return ret
    }()

    let labelHTTPSNotice: UILabel = {
        let ret = UILabel()
        ret.text = L10n.text("[https] is required and used for security reason")
        ret.textColor = .gray
        ret.font = .systemFont(ofSize: 12, weight: .regular)
        ret.textAlignment = .center
        return ret
    }()

    let buttonLearnMore: UIButton = {
        let ret = UIButton()
        ret.setTitle(L10n.text("Get One"), for: .normal)
        ret.setTitleColor(.accent, for: .normal)
        ret.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return ret
    }()

    let buttonBeginLogin: UIButton = {
        let button = UIButton()
        button.isPointerInteractionEnabled = true
        button.tintColor = .accent
        let largeConfig = UIImage.SymbolConfiguration(
            pointSize: 32,
            weight: .bold,
            scale: .large
        )
        let img = UIImage(
            systemName: "arrow.right.circle.fill",
            withConfiguration: largeConfig
        )
        button.setImage(img, for: .normal)
        return button
    }()

    let buttonAcknowledge: UIButton = {
        let ret = UIButton()
        ret.setTitle(L10n.text("Made with love by @Lakr233"), for: .normal)
        ret.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        ret.setTitleColor(.systemGray3, for: .normal)
        return ret
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let ret = UIActivityIndicatorView()
        ret.alpha = 0
        ret.startAnimating()
        return ret
    }()

    let buttonCancel: UIButton = {
        let button = UIButton()
        button.setTitle(L10n.text("Cancel Login"), for: .normal)
        button.setTitleColor(.systemPink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.alpha = 0
        button.isUserInteractionEnabled = false
        return button
    }()

    var inputUrl: String = ""
    var requestCancel: Bool = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()

        appendView()
        setupLayout()
        buttonBeginLogin.addTarget(self, action: #selector(beginLogin), for: .touchUpInside)
        textFieldInputHost.addTarget(self, action: #selector(updateText), for: .editingChanged)
        textFieldInputHost.delegate = self
        buttonAcknowledge.addTarget(self, action: #selector(openAcknowledge), for: .touchUpInside)
        buttonLearnMore.addTarget(self, action: #selector(openLearnMore), for: .touchUpInside)
        buttonCancel.addTarget(self, action: #selector(cancelLogin), for: .touchUpInside)

        navigationItem.leftBarButtonItem = .init(
            title: L10n.text("Cancel"),
            style: .plain,
            target: self,
            action: #selector(dismissController)
        )
    }

    @objc func dismissController() {
        dismiss(animated: true)
    }

    func appendView() {
        view.addSubview(icon)
        view.addSubview(labelWelcome)
        view.addSubview(textFieldInputHost)
        view.addSubview(labelLoginHint)
        view.addSubview(labelHTTPSNotice)
        view.addSubview(buttonLearnMore)
        view.addSubview(buttonBeginLogin)
        view.addSubview(activityIndicator)
        view.addSubview(buttonAcknowledge)
        view.addSubview(buttonCancel)
    }

    func setupLayout() {
        let padding: Double = 32
        let spacing: CGFloat = 16
        icon.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.width.height.equalTo(50)
        }
        labelWelcome.snp.makeConstraints { x in
            x.left.equalToSuperview().offset(padding)
            x.right.equalToSuperview().offset(-padding)
            x.top.equalTo(icon.snp.bottom).offset(spacing)
        }
        labelLoginHint.snp.makeConstraints { x in
            x.left.equalTo(textFieldInputHost.snp.left)
            x.top.equalTo(labelWelcome.snp.bottom).offset(spacing)
            x.height.equalTo(20)
        }
        buttonLearnMore.snp.makeConstraints { x in
            x.right.equalTo(textFieldInputHost.snp.right)
            x.centerY.equalTo(labelLoginHint.snp.centerY)
            x.height.equalTo(20)
        }
        textFieldInputHost.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.height.equalTo(40)
            x.width.equalTo(300)
            x.top.equalTo(labelLoginHint.snp.bottom).offset(spacing)
            x.centerY.equalToSuperview()
        }
        labelHTTPSNotice.snp.makeConstraints { x in
            x.left.equalTo(textFieldInputHost.snp.left)
            x.top.equalTo(textFieldInputHost.snp.bottom).offset(spacing)
            x.height.equalTo(20)
        }
        buttonBeginLogin.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.height.equalTo(32)
            x.width.equalTo(32)
            x.top.equalTo(labelHTTPSNotice.snp.bottom).offset(spacing)
        }
        activityIndicator.snp.makeConstraints { x in
            x.center.equalTo(buttonBeginLogin.snp.center)
        }
        buttonAcknowledge.snp.makeConstraints { x in
            x.bottom.equalToSuperview().offset(-20)
            x.centerX.equalToSuperview()
        }
        buttonCancel.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.top.equalTo(buttonBeginLogin.snp.bottom).offset(spacing)
        }
    }

    var currentSize: CGSize = .init(width: 0, height: 0)
    var previousLayoutSize: CGSize = .init()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousLayoutSize == view.frame.size {
            return
        }
        var width = view.frame.width - 40 // padding
        if width > kTextFieldMaxWidth { width = kTextFieldMaxWidth }
        textFieldInputHost.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }

    func switchToLoading() {
        buttonBeginLogin.isUserInteractionEnabled = false
        textFieldInputHost.isUserInteractionEnabled = false
        buttonLearnMore.isUserInteractionEnabled = false
        buttonCancel.isUserInteractionEnabled = true
        withUIKitAnimation { [self] in
            buttonBeginLogin.alpha = 0
            activityIndicator.alpha = 1
            buttonCancel.alpha = 1
        }
    }

    func switchToInteractive() {
        buttonBeginLogin.isUserInteractionEnabled = true
        textFieldInputHost.isUserInteractionEnabled = true
        buttonLearnMore.isUserInteractionEnabled = true
        buttonCancel.isUserInteractionEnabled = false
        withUIKitAnimation { [self] in
            buttonBeginLogin.alpha = 1
            activityIndicator.alpha = 0
            buttonCancel.alpha = 0
        }
    }

    @objc
    func beginLogin() {
        if textFieldInputHost.text?.hasPrefix("https://") ?? false {
            textFieldInputHost.text?.removeFirst("https://".count)
        }
        if textFieldInputHost.text?.hasPrefix("http://") ?? false {
            textFieldInputHost.text?.removeFirst("http://".count)
        }
        if textFieldInputHost.text?.hasSuffix("/") ?? false {
            textFieldInputHost.text?.removeLast("/".count)
        }
        updateText()
        buttonBeginLogin.puddingAnimate()
        guard !inputUrl.contains("/"),
              let host = URL(string: "https://" + inputUrl)?.host
        else {
            presentError(L10n.text("Invalid Host"))
            return
        }
        guard let challenge = LoginChallenge(host: host) else {
            presentError(L10n.text("Invalid Request"))
            assertionFailure() // checked host before
            return
        }

        let alert = UIAlertController(
            title: L10n.text("You are connecting to\nhttps://%@", challenge.requestHost),
            message: L10n.text("Please sign in with your username and password there, and authorize this session with Misskey OAuth."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.text("Continue"), style: .default, handler: { [weak self] _ in
            self?.processedToLogin(withSession: challenge)
        }))
        alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func processedToLogin(withSession challenge: LoginChallenge) {
        print("====== 🔒 ======")
        print("Begin Login")
        print("[i] Challenge \(challenge.requestSession)")
        print("[i] Checker \(challenge.requestRecipeCheck)")
        print("================")

        switchToLoading()

        let authenticSession = presentAuthenticateController(request: challenge)
        requestCancel = false
        DispatchQueue.global().async {
            var receipt: LoginChallengeReceipt?
            var maxCount = 180 // prevent crashing the server
            while !self.requestCancel, receipt == nil {
                maxCount -= 1
                sleep(3)
                let sem = DispatchSemaphore(value: 0)
                self.challengeCheck(with: challenge) { ans in
                    receipt = ans
                    sem.signal()
                }
                sem.wait()
            }
            withMainActor {
                if authenticSession?.isVisible ?? false {
                    authenticSession?.dismiss(animated: true)
                }
                defer { self.switchToInteractive() }

                if let receipt {
                    Account.shared.store(receipt: receipt)
                    Account.shared.activate(receiptID: receipt.id)
                    self.dismiss(animated: true)
                } else {
                    presentError(L10n.text("Login Challenge Failed"))
                }
            }
        }
    }

    @objc
    func cancelLogin() {
        HapticGenerator.make(.success)
        requestCancel = true
        buttonCancel.isUserInteractionEnabled = false
        withUIKitAnimation {
            self.buttonCancel.alpha = 0
        }
    }

    func presentAuthenticateController(request: LoginChallenge) -> SFSafariViewController? {
        assert(Thread.isMainThread)

        // before connecting to the host, make a request and pop that
        // "do you wish to connect/allow local network access?"
        // then user is free to go
        URLSession
            .shared
            .dataTask(with: request.requestURL) { _, _, _ in }
            .resume()
        let controller = SFSafariViewController(url: request.requestURL)
        controller.prepareModalSheet(style: .formSheet, preferredSize: nil)
        present(controller, animated: true)
        return controller
    }

    func challengeCheck(
        with request: LoginChallenge,
        completion: @escaping (LoginChallengeReceipt?) -> Void
    ) {
        DispatchQueue.global().async {
            completion(request.check())
        }
    }

    @objc
    func updateText() {
        debugPrint("text changed to: \(textFieldInputHost.text ?? "")")
        inputUrl = textFieldInputHost.text ?? ""
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        withMainActor { self.beginLogin() }
        return true
    }

    @objc
    func openAcknowledge() {
        UIApplication.shared.open(
            URL(string: "https://github.com/Lakr233/Kimis")!,
            options: [:],
            completionHandler: nil
        )
    }

    @objc
    func openLearnMore() {
        UIApplication.shared.open(
            URL(string: "https://github.com/misskey-dev/misskey")!,
            options: [:],
            completionHandler: nil
        )
    }
}
