//
//  UserViewController+Profile.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import Combine
import Source
import UIKit

extension UserViewController {
    class ProfileView: UIView {
        static let avatarSize: CGSize = .init(width: 80, height: 80)
        static let bannerImageHeight: CGFloat = 200
        static let maxContentWidth: CGFloat = IH.contentMaxWidth
        static let verticalSpacing: CGFloat = 12

        enum Status {
            case loading
            case failure
            case normal
        }

        var status: Status = .loading { didSet { if status != oldValue {
            updateViewStatus()
        } } }
        var profile: UserProfile? { didSet { if profile != oldValue {
            updateDataSource()
            setNeedsLayout()
        } } }

        weak var source: Source? = Account.shared.source
        var cancellable = Set<AnyCancellable>()

        @Published var contentHeight: CGFloat = 0
        @Published var boundsWidth: CGFloat = 0

        let bannerImageView = MKImageView()
        let bannerImageBlur: UIVisualEffectView = {
            let effect = UIBlurEffect(style: .systemThickMaterial)
            let view = UIVisualEffectView(effect: effect)
            return view
        }()

        var bannerImageViewExtraHeight: CGFloat = 0 {
            didSet { setNeedsLayout() }
        }

        let avatarImageView = MKRoundedImageView()
        let buttonStack = ProfileButton()
        let userTextView = TextView(editable: false, selectable: true, disableLink: true)
        let mainTextView = TextView(editable: false, selectable: true)
        let segmentStack = UIStackView()
        let separator = UIView()

        let segmentNoteButton = SegmentButton(title: L10n.text("Note"))
        let segmentRepliesButton = SegmentButton(title: L10n.text("w/ Replies"))
        let segmentMediaButton = SegmentButton(title: L10n.text("Media"))

        let progressView = UIActivityIndicatorView()
        let failureIcon = UIImageView()
        let failureHint = UILabel()
        let retryButton = UIButton()

        var representUser: String = "" {
            didSet { updateDataSource() }
        }

        init() {
            super.init(frame: .zero)

            let views: [UIView] = [
                bannerImageView, bannerImageBlur, avatarImageView,
                buttonStack,
                userTextView, mainTextView,
                segmentStack, separator,
                progressView, failureIcon, failureHint, retryButton,
            ]
            addSubviews(views)

            avatarImageView.option.previewEnabled = true
            bannerImageView.option.previewEnabled = true

            failureIcon.image = .init(systemName: "exclamationmark.triangle.fill")
            failureIcon.contentMode = .scaleAspectFit
            failureIcon.tintColor = .systemBlackAndWhite

            failureHint.text = L10n.text("Unknown/Network Error Occurred")
            failureHint.minimumScaleFactor = 0.5
            failureHint.numberOfLines = 1
            failureHint.textColor = .systemBlackAndWhite
            failureHint.font = .systemFont(ofSize: 14, weight: .semibold)
            failureHint.textAlignment = .center

            let underline: [NSAttributedString.Key: Any] = [
                .font: UIFont.rounded(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.accent,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]
            let text = NSMutableAttributedString(string: L10n.text("Retry"), attributes: underline)
            retryButton.setAttributedTitle(text, for: .normal)

            avatarImageView.layer.borderWidth = 2
            avatarImageView.layer.borderColor = UIColor.white
                .withAlphaComponent(0.5)
                .cgColor

            segmentStack.axis = .horizontal
            segmentStack.distribution = .fillEqually
            segmentStack.spacing = Self.verticalSpacing
            segmentStack.addArrangedSubviews([
                segmentNoteButton,
                segmentRepliesButton,
                segmentMediaButton,
            ])

            separator.backgroundColor = .separator

            $boundsWidth
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] width in
                    self?.renderText(usingWidth: width)
                }
                .store(in: &cancellable)

            updateViewStatus()
            updateDataSource()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension UserViewController.ProfileView {
    override func layoutSubviews() {
        super.layoutSubviews()

        let this = self
        let bounds = this.bounds

        defer { boundsWidth = bounds.width }

        let padding: CGFloat = IH.preferredPadding(usingWidth: bounds.width)
        var contentWidth = bounds.width - padding * 2
        if contentWidth > Self.maxContentWidth { contentWidth = Self.maxContentWidth }
        let contentLeftAlignment = (bounds.width - contentWidth) / 2
        let verticalSpacing: CGFloat = Self.verticalSpacing

        bannerImageView.frame = CGRect(
            x: 0,
            y: -(75 + bannerImageViewExtraHeight),
            width: bounds.width,
            height: Self.bannerImageHeight + bannerImageViewExtraHeight
        )
        bannerImageBlur.frame = bannerImageView.frame

        avatarImageView.frame = CGRect(
            x: contentLeftAlignment,
            y: bannerImageView.frame.maxY - Self.avatarSize.height / 2,
            width: Self.avatarSize.width,
            height: Self.avatarSize.height
        )

        buttonStack.frame = CGRect(
            x: avatarImageView.frame.maxX + padding,
            y: bannerImageView.frame.maxY,
            width: contentWidth - padding - avatarImageView.frame.width,
            height: avatarImageView.frame.height / 2
        )

        let userTextHeight = userTextView
            .sizeThatFits(CGSize(width: contentWidth, height: .infinity))
            .height
        userTextView.frame = CGRect(
            x: contentLeftAlignment,
            y: avatarImageView.frame.maxY + verticalSpacing,
            width: contentWidth,
            height: userTextView.attributedText.length > 0 ? userTextHeight : 100
        )

        let mainTextHeight = mainTextView
            .sizeThatFits(CGSize(width: contentWidth, height: .infinity))
            .height
        mainTextView.frame = CGRect(
            x: contentLeftAlignment,
            y: userTextView.frame.maxY + verticalSpacing,
            width: contentWidth,
            height: mainTextView.attributedText.length > 0 ? mainTextHeight : 100
        )

        segmentStack.frame = CGRect(
            x: contentLeftAlignment,
            y: mainTextView.frame.maxY + verticalSpacing,
            width: contentWidth,
            height: SegmentButton.height
        )

        separator.frame = CGRect(
            x: 0,
            y: segmentStack.frame.maxY + verticalSpacing,
            width: bounds.width,
            height: 0.5
        )

        let contentRect = CGRect(
            x: contentLeftAlignment,
            y: mainTextView.frame.minY,
            width: contentWidth,
            height: segmentStack.frame.maxY - mainTextView.frame.minY
        )

        let failureHintHeight = failureHint
            .sizeThatFits(CGSize(width: contentWidth, height: .infinity))
            .height
        failureHint.frame = CGRect(
            x: contentLeftAlignment,
            y: contentRect.midY - failureHintHeight / 2,
            width: contentWidth,
            height: failureHintHeight
        )

        let failureIconSize = CGSize(width: 24, height: 24)
        failureIcon.frame = CGRect(
            x: failureHint.frame.midX - failureIconSize.width / 2,
            y: failureHint.frame.minY - verticalSpacing - failureIconSize.height,
            width: failureIconSize.width,
            height: failureIconSize.height
        )

        let progressViewSize = progressView.intrinsicContentSize
        progressView.frame = CGRect(
            x: contentRect.midX - progressViewSize.width / 2,
            y: failureHint.frame.midY - progressViewSize.height / 2,
            width: progressViewSize.width,
            height: progressViewSize.height
        )

        let retryButtonSize = retryButton
            .sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        retryButton.frame = CGRect(
            x: contentRect.midX - retryButtonSize.width / 2,
            y: failureHint.frame.maxY + verticalSpacing,
            width: retryButtonSize.width,
            height: retryButtonSize.height
        )

        contentHeight = separator.frame.maxY.rounded()
    }

    func reset() {
        buttonStack.profile = nil
        bannerImageView.loadImage(with: nil)
        bannerImageBlur.isHidden = false
        avatarImageView.loadImage(with: nil)
        userTextView.attributedText = .init()
        mainTextView.attributedText = .init()

        userTextView.attributedText = NSAttributedString(string: representUser, attributes: [
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.gray,
        ])
    }

    func updateViewStatus() {
        for view in subviews {
            view.isHidden = true
        }
        bannerImageView.isHidden = false
        bannerImageBlur.isHidden = false
        avatarImageView.isHidden = false
        separator.isHidden = false
        userTextView.isHidden = false
        switch status {
        case .loading:
            progressView.isHidden = false
            progressView.startAnimating()
        case .normal:
            buttonStack.isHidden = false
            userTextView.isHidden = false
            mainTextView.isHidden = false
            segmentStack.isHidden = false
        case .failure:
            failureIcon.isHidden = false
            failureHint.isHidden = false
            retryButton.isHidden = false
        }
    }

    func updateDataSource() {
        guard let profile else {
            reset()
            return
        }

        buttonStack.profile = profile

        // if user does not have a banner image, use avatar + blur
        if profile.bannerUrl?.isEmpty ?? true {
            bannerImageView.loadImage(with: .init(
                url: profile.avatarUrl,
                blurHash: profile.avatarBlurhash,
                sensitive: false
            ))
            bannerImageBlur.alpha = 1
            bannerImageBlur.isHidden = false
        } else {
            bannerImageView.loadImage(with: .init(
                url: profile.bannerUrl,
                blurHash: profile.bannerBlurhash,
                sensitive: false
            ))
            bannerImageBlur.alpha = 0
            bannerImageBlur.isHidden = true
        }

        avatarImageView.loadImage(with: .init(
            url: profile.avatarUrl,
            blurHash: profile.avatarBlurhash,
            sensitive: false
        ))

        renderText(usingWidth: boundsWidth)

        setNeedsLayout()
    }

    func renderText(usingWidth width: CGFloat) {
        guard let profile else {
            reset()
            return
        }

        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = false
            parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
            parser.paragraphStyle.paragraphSpacing = Self.verticalSpacing
                - parser.paragraphStyle.lineSpacing
            return parser
        }()
        userTextView.attributedText = textParser.compileUserProfileHeader(with: profile)
        mainTextView.attributedText = textParser.compileUserDescription(with: profile)

        setNeedsLayout()
    }
}
