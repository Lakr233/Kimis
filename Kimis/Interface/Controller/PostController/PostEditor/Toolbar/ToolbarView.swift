//
//  ToolbarView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/6.
//

import Combine
import MorphingLabel
import Source
import UIKit

extension PostEditorToolbarView {
    func createToolButtons() -> [ToolItemButton] {
        [
            createButtonsForVisibility(),

            createButtonsForPictureAttachment(),
            createButtonsForFileAttachments(),
            createButtonsForCloudDrive(),

            createButtonsForPoll(),

            createButtonsForEmoji(),
            createButtonsForUser(),
        ].flatMap { $0 }
    }
}

class PostEditorToolbarView: UIView {
    weak var source: Source? = Account.shared.source
    var cancellable: Set<AnyCancellable> = []

    let post: Post
    let sep = UIView()
    let stackView = UIStackView()
    let scrollView = UIScrollView()
    let textLengthLimitLabel = LTMorphingLabel()

    var toolButtons: [ToolItemButton] = []

    init(post: Post) {
        self.post = post
        super.init(frame: .zero)
        toolButtons = createToolButtons()

        backgroundColor = .platformBackground

        frame.size.height = Self.preferredHeight

        addSubview(sep)
        sep.backgroundColor = .separator
        sep.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }

        textLengthLimitLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textLengthLimitLabel.numberOfLines = 1
        textLengthLimitLabel.adjustsFontSizeToFitWidth = true
        textLengthLimitLabel.minimumScaleFactor = 0.1
        textLengthLimitLabel.morphingEffect = .evaporate
        textLengthLimitLabel.textAlignment = .right
        addSubview(textLengthLimitLabel)
        textLengthLimitLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Self.spacing)
            make.top.equalToSuperview().offset(Self.spacing)
            make.width.equalTo(100)
            make.height.equalTo(Self.toolItemSize)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.clipsToBounds = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Self.spacing)
            make.right.equalTo(textLengthLimitLabel.snp.left).offset(-Self.spacing)
            make.top.equalToSuperview().offset(Self.spacing)
            make.height.equalTo(Self.toolItemSize)
        }

        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = Self.spacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        for button in toolButtons {
            button.snp.makeConstraints { make in
                make.width.height.equalTo(Self.toolItemSize)
            }
            stackView.addArrangedSubview(button)
        }

        post.updated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcons()
                self?.updateViewsForPost()
            }
            .store(in: &cancellable)
        updateViewsForPost()

        setNeedsLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        scrollView.contentSize = CGSize(
            width: stackView.frame.width,
            height: 0
        )
    }

    func updateIcons() {
        for toolItem in toolButtons {
            toolItem.updateAppearance()
        }
    }

    func updateViewsForPost() {
        withUIKitAnimation {
            self.updateTextLimit(withPost: self.post)
        }
    }

    func updateTextLimit(withPost post: Post) {
        var textLeft = source?.instance.maxNoteTextLength ?? 0
        textLeft -= post.text.count
        textLengthLimitLabel.text = "\(textLeft)"
        if textLeft <= 0 {
            textLengthLimitLabel.textColor = .systemRed
        } else if textLeft <= 10 {
            textLengthLimitLabel.textColor = .systemOrange
        } else {
            textLengthLimitLabel.textColor = .accent
        }
    }

    func resolveFilesAndUpload(at files: [URL]) {
        print("[*] preparing \(files.count) item(s) for upload")
        withMainActor {
            let controller = AttachUploadController(post: self.post, files: files)
            self.insertViewController(controller)
        }
    }

    func insertViewController(_ controller: UIViewController) {
        guard let nav = parentViewController?.navigationController else {
            assertionFailure()
            return
        }
        nav.pushViewController(controller, animated: true)
    }
}
