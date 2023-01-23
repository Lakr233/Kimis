//
//  PostEditorController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/6.
//

import Combine
import Source
import UIKit
import UniformTypeIdentifiers

private let stubContext = NoteCell.Context(kind: .main)

class PostEditorController: ViewController, UIScrollViewDelegate, UIDropInteractionDelegate {
    var _title: String {
        if renoteId != nil { return "Renote" }
        if replyId != nil { return "Reply" }
        return "Post"
    }

    var renoteId: NoteID?
    var replyId: NoteID?
    let textParser: TextParser = {
        let parser = TextParser()
        parser.options.compactPreview = false
        parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
        parser.paragraphStyle.paragraphSpacing = 0
        return parser
    }()

    let post: Post = .init()

    static let spacing = CGFloat(12)

    init() {
        toolbar = .init(post: post)
        editor = .init(post: post, spacing: Self.spacing, textParser: textParser)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var keyboardVisible: Bool = false

    let container = UIScrollView()
    let userAvatar = AccountAvatarView()
    let avatarHint = UIImageView()
    let avatarHintBackground = UIView()
    let userTitle = TextView.noneInteractive()
    let editor: PostEditorView
    let renotePreview = NotePreviewSimple()
    let toolbar: PostEditorToolbarView

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedAround))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        navigationItem.leftBarButtonItems = [
            .init(
                title: "Cancel",
                style: .plain,
                target: self,
                action: #selector(cancelButtonTapped)
            ),
        ]
        navigationItem.rightBarButtonItems = [
            .init(
                title: "Send",
                style: .done,
                target: self,
                action: #selector(sendButtonTapped)
            ),
        ]

        title = _title
        container.alwaysBounceVertical = true
        container.delegate = self
        view.addSubview(container)
        container.addSubviews([
            userAvatar,
            avatarHintBackground,
            avatarHint,
            userTitle,
            editor,
            renotePreview,
        ])

        userAvatar.isUserInteractionEnabled = false
        userTitle.isUserInteractionEnabled = false

        avatarHint.tintColor = .accent
        avatarHint.contentMode = .scaleAspectFit
        avatarHintBackground.backgroundColor = .white
        if replyId != nil {
            avatarHint.image = UIImage(systemName: "arrowshape.turn.up.left.circle.fill")
        } else if renoteId != nil {
            avatarHint.image = UIImage(systemName: "arrowshape.turn.up.right.circle.fill")
        } else {
            avatarHint.isHidden = true
            avatarHintBackground.isHidden = true
        }

        if renoteId != nil {
            editor.placeholderText = "Renote"
        }
        if let replyId, let initialNote = source?.notes.retain(replyId) {
            defer { toolbar.updateIcons() }
            editor.placeholderText = "Reply"
            if let initialVis = Post.Visibility(rawValue: initialNote.visibility) {
                post.visibility = initialVis
            }
            if let user = source?.users.retain(initialNote.userId) {
                editor.placeholderText = "Reply to \(textParser.trimToPlainText(from: user.name))"
            }
            var replyingTo = [String]()
            var note: Note? = initialNote
            while let lookup = note, let user = source?.users.retain(lookup.userId) {
                note = nil
                replyingTo.append(user.absoluteUsername)
                if let nextReplyId = lookup.replyId {
                    note = source?.notes.retain(nextReplyId)
                }
            }
            replyingTo = replyingTo.filter {
                $0.lowercased() != source?.user.absoluteUsername.lowercased()
            }
            replyingTo.removeDuplicates()
            if !replyingTo.isEmpty {
                let quote = replyingTo.joined(separator: " ")
                post.text = quote + (replyingTo.count >= 3 ? "\n\n" : " ")
            }
        }

        post.updated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSendButtonAvailability()
            }
            .store(in: &cancellable)

        editor.$editorHeight
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                withUIKitAnimation { self.updateFrames() }
            }
            .store(in: &cancellable)

        source?.notesChange
            .filter { [weak self] val in
                val == self?.renoteId || val == self?.replyId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrames()
            }
            .store(in: &cancellable)

        view.addSubview(toolbar)

        updateSendButtonAvailability()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateFrames()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        editor.activateFocus()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let key = press.key else { continue }
            if key.keyCode == .keyboardEscape {
                cancelButtonTapped()
                didHandleEvent = true
            }
        }
        if didHandleEvent == false {
            super.pressesBegan(presses, with: event)
        }
    }

    func updateFrames() {
        let bounds = view.bounds // container.frame = view.bounds
        if bounds.width == 0 { return }

        textParser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: view.bounds.width)
        let toolbarHeight = PostEditorToolbarView.preferredHeight
            + view.safeAreaInsets.bottom
        toolbar.frame = CGRect(x: 0, y: bounds.height - toolbarHeight, width: bounds.width, height: toolbarHeight)
        container.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - toolbarHeight)

        if let profile = Account.shared.source?.user {
            let user = User.converting(profile)
            userTitle.attributedText = textParser
                .compileUserHeader(with: user, lineBreak: false)
        }

        let padding = IH.preferredPadding(usingWidth: bounds.width)
        let spacing: CGFloat = Self.spacing
        var heightAnchor: CGFloat = 0

        let avatarSize = NoteView.defaultAvatarSize
            + IH.preferredAvatarSizeOffset(usingWidth: bounds.width)
        userAvatar.frame = CGRect(
            x: padding,
            y: heightAnchor + spacing,
            width: avatarSize,
            height: avatarSize
        )
        heightAnchor = userAvatar.frame.maxY + spacing

        let tintIconSize: CGFloat = avatarSize / 3
        avatarHint.frame = CGRect(
            x: userAvatar.frame.maxX - tintIconSize,
            y: userAvatar.frame.maxY - tintIconSize,
            width: tintIconSize,
            height: tintIconSize
        )
        avatarHintBackground.frame = avatarHint.frame.inset(by: UIEdgeInsets(inset: 4))
        avatarHintBackground.layer.cornerRadius = avatarHintBackground.frame.width / 2

        let contentAlign = userAvatar.frame.maxX + spacing
        let contentWidth = bounds.width - contentAlign - padding

        userTitle.frame = CGRect(
            x: contentAlign,
            y: userAvatar.frame.minY,
            width: contentWidth,
            height: userTitle.attributedText.measureHeight(usingWidth: contentWidth)
        )
        heightAnchor = userTitle.frame.maxY

        editor.frame = CGRect(
            x: contentAlign,
            y: heightAnchor + spacing,
            width: contentWidth,
            height: editor.editorHeight
        )
        heightAnchor = editor.frame.maxY + spacing

        if let renoteId {
            if renotePreview.snapshot == nil {
                renotePreview.snapshot = .init(
                    usingWidth: contentWidth,
                    target: renoteId,
                    context: stubContext, // weak var context will get this released
                    textParser: textParser
                )
            }
            // notes may change
            renotePreview.snapshot?.render(usingWidth: contentWidth)
            renotePreview.updateNoteData()
            let height = renotePreview.snapshot?.height ?? 0
            assert(height > 0)
            renotePreview.frame = CGRect(
                x: contentAlign,
                y: heightAnchor,
                width: contentWidth,
                height: height
            )
            heightAnchor = renotePreview.frame.maxY + spacing
        } else {
            renotePreview.isHidden = true
        }

        container.contentSize = CGSize(width: 0, height: heightAnchor + 50)
    }

    func updateSendButtonAvailability() {
        let enabled = isPostPossibleValidated()
        navigationItem.rightBarButtonItems?.forEach {
            $0.isEnabled = enabled
        }
    }

    func isPostPossibleValidated() -> Bool {
        let textLimit = source?.instance.maxNoteTextLength ?? 0
        if post.text.count > textLimit { return false }
        if !post.hasContent, renoteId == nil { return false }
        if let poll = post.poll {
            if poll.choices.count < 2 { return false }
            if Set(poll.choices).count != poll.choices.count { return false }
            if poll.choices.contains("") { return false }
        }
        return true
    }

    @objc func tappedAround() {
        if keyboardVisible {
            becomeFirstResponder()
            resignFirstResponder()
        } else {
            editor.activateFocus()
        }
    }

    @objc func cancelButtonTapped() {
        if editor.post == .init() {
            dismiss(animated: true)
        } else {
            let alert = UIAlertController(title: "Discard", message: "Are you sure about it?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }

    @objc func sendButtonTapped() {
        guard let source else { return }
        let post = post
        let renote = renoteId
        let reply = replyId

        let alert = UIAlertController(title: "✈️", message: "Sending Post", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.global().async {
            let result = source.req.requestNoteCreate(forPost: post, renote: renote, reply: reply)
            if result != nil, !source.timeline.updating {
                source.timeline.requestUpdate(direction: .newer)
            }
            DispatchQueue.global().async {
                if let noteId = result?.noteId { NotificationCenter.default.post(name: .postSent, object: noteId) }
                if let noteId = self.replyId { NotificationCenter.default.post(name: .postSent, object: noteId) }
                if let noteId = self.renoteId { NotificationCenter.default.post(name: .postSent, object: noteId) }
            }
            withMainActor {
                alert.dismiss(animated: true) {
                    if result != nil {
                        self.dismiss(animated: true)
                    } else {
                        let alert = UIAlertController(title: "Error", message: "Unable to send, please try again later", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        print("[*] PostEditorController drop delegate", interaction, session, "\n", session.items.map(\.itemProvider))
        var canHandleDrop = true
        for provider in session.items.map(\.itemProvider) {
            if session.localDragSession != nil {
                canHandleDrop = false
            }
            if canHandleDrop, provider.hasItemConformingToTypeIdentifier(UTType.folder.identifier) {
                canHandleDrop = false
            }
            if canHandleDrop, !provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
                canHandleDrop = false
            }
        }
        print("[*] PostEditorController drop delegate reply \(session) canHandleDrop? \(canHandleDrop)")
        return canHandleDrop
    }

    func dropInteraction(_: UIDropInteraction, sessionDidUpdate _: UIDropSession) -> UIDropProposal {
        .init(operation: .copy)
    }

    func dropInteraction(_: UIDropInteraction, sessionDidEnter _: UIDropSession) {
        withUIKitAnimation {
            self.view.backgroundColor = .accent.withAlphaComponent(0.1)
        }
    }

    func dropInteraction(_: UIDropInteraction, sessionDidEnd _: UIDropSession) {
        withUIKitAnimation {
            self.view.backgroundColor = .platformBackground
        }
    }

    func dropInteraction(_: UIDropInteraction, performDrop session: UIDropSession) {
        let items = session.items
        let group = DispatchGroup()
        var urls = [URL]()
        let lock = NSLock()
        let copyToTempDir = temporaryDirectory
            .appendingPathExtension("Drop")
        try? FileManager.default.createDirectory(at: copyToTempDir, withIntermediateDirectories: true)
        for provider in items.map(\.itemProvider) {
            group.enter()
            provider.loadFileRepresentation(
                forTypeIdentifier: UTType.item.identifier
            ) { url, _ in
                lock.lock()
                defer { lock.unlock() }
                defer { group.leave() }
                guard let url else { return }
                let rand = copyToTempDir
                    .appendingPathComponent(UUID().uuidString)
                try? FileManager.default.createDirectory(at: rand, withIntermediateDirectories: true)
                let newUrl = rand.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: newUrl)
                try? FileManager.default.copyItem(at: url, to: newUrl)
                guard FileManager.default.fileExists(atPath: newUrl.path) else { return }
                urls.append(newUrl)
            }
        }

        DispatchQueue.global().async {
            group.wait()
            guard !urls.isEmpty else {
                presentError("Unable to load file")
                return
            }
            print("[*] drop files\n", urls.map(\.path).joined(separator: "\n"))
            withMainActor {
                self.toolbar.resolveFilesAndUpload(at: urls)
            }
        }
    }
}
