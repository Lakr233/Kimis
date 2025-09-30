//
//  PostEditorView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/2.
//

import Combine
import GlyphixTextFx
import Source
import UIKit

private let kDefaultPlaceholderText = "How's it going?"

class PostEditorView: UIView, UITextViewDelegate {
    weak var source: Source? = Account.shared.source
    var cancellable: Set<AnyCancellable> = []

    @Published var editorHeight: CGFloat = 100

    let post: Post

    private let textParser: TextParser

    private let spacing: CGFloat
    private let placeholder = TextView.noneInteractive()
    private let visibilityButton = UIButton()
    private let textLimitLabel = GlyphixTextLabel()
    private let mainTextEditor = TextView(editable: true, selectable: true, disableLink: true)
    private let pollEditor: PostEditorPollView
    private let attachmentsEditor: PostEditorAttachmentView

    let toolbar: PostEditorToolbarView

    var placeholderText: String {
        get { placeholder.text ?? "" }
        set { placeholder.text = newValue }
    }

    init(
        post: Post,
        spacing: CGFloat,
        textParser: TextParser
    ) {
        self.post = post
        self.textParser = textParser
        self.spacing = spacing
        toolbar = .init(post: post)
        pollEditor = .init(post: post, spacing: spacing / 2)
        attachmentsEditor = .init(post: post, spacing: spacing / 2)

        super.init(frame: .zero)

        clipsToBounds = false
        addSubviews([
            mainTextEditor,
            placeholder,
            textLimitLabel,
            pollEditor,
            attachmentsEditor,
        ])
        placeholder.textContainer.maximumNumberOfLines = 1
        placeholder.isUserInteractionEnabled = false
        placeholderText = kDefaultPlaceholderText
        placeholder.font = textParser.getFont()
        placeholder.textColor = textParser.color.secondary
        mainTextEditor.text = ""
        mainTextEditor.delegate = self
        mainTextEditor.font = textParser.getFont()
        textLimitLabel.font = textParser.getMonospacedFont()
        textLimitLabel.textColor = textParser.color.secondary

        mainTextEditor.inputAccessoryView = toolbar

        post.updated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.postDidUpdate()
            }
            .store(in: &cancellable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mainTextEditor.font = textParser.getFont()
        updateViewFrame()
    }

    func postDidUpdate() {
        resyncValues()
        updateEditorHints()
        pollEditor.reloadAndPrepareForNewFrame()
        attachmentsEditor.reloadAndPrepareForNewFrame()
        updateViewFrame()
    }

    func resyncValues() {
        if mainTextEditor.text != post.text {
            mainTextEditor.executeFocusedUpdate { mainTextEditor in
                mainTextEditor.text = post.text
            }
        }
    }

    func updateViewFrame() {
        var heightAnchor: CGFloat = 0
        let width = bounds.width

        assert(mainTextEditor.font != nil)
        let textHeight = max(
            NSMutableAttributedString(string: "AA55", attributes: [
                .font: mainTextEditor.font ?? .systemFont(ofSize: 0),
            ]).measureHeight(usingWidth: .infinity),
            mainTextEditor.attributedText.measureHeight(usingWidth: width)
        )
        mainTextEditor.frame = CGRect(
            x: 0, y: heightAnchor,
            width: width, height: textHeight
        )
        let holderHeight = placeholder.attributedText.measureHeight(
            usingWidth: width, lineLimit: 1
        )
        placeholder.frame = CGRect(
            x: 0,
            y: heightAnchor + textHeight - holderHeight,
            width: width,
            height: holderHeight
        )
        placeholder.isHidden = mainTextEditor.attributedText.length > 0
        heightAnchor = mainTextEditor.frame.maxY

        pollEditor.frame = CGRect(
            x: 0,
            y: heightAnchor + spacing,
            width: width,
            height: pollEditor.contentSize.height
        )
        if pollEditor.contentSize.height <= 0 {
            pollEditor.isHidden = true
        } else {
            pollEditor.isHidden = false
            heightAnchor = pollEditor.frame.maxY
        }

        attachmentsEditor.frame = CGRect(
            x: 0,
            y: heightAnchor + spacing,
            width: width,
            height: attachmentsEditor.contentSize.height
        )
        if attachmentsEditor.contentSize.height <= 0 {
            attachmentsEditor.isHidden = true
        } else {
            attachmentsEditor.isHidden = false
            heightAnchor = attachmentsEditor.frame.maxY
        }

        editorHeight = heightAnchor
    }

    func activateFocus() {
        mainTextEditor.becomeFirstResponder()
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView == mainTextEditor { post.text = textView.text }
        withMainActor(delay: 0.1) { self.keepSelecionInFocus(textView) }
    }

    func textView(_: UITextView, shouldInteractWith _: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
        false
    }

    func textView(_: UITextView, shouldInteractWith _: NSTextAttachment, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
        false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        post.selectionHint = textView.selectedRange
        withMainActor(delay: 0.1) { self.keepSelecionInFocus(textView) }
    }

    func keepSelecionInFocus(_ textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange,
              textView.selectedRange.length == 0
        else { return }
        let caretRect = textView.caretRect(for: selectedRange.end)
//        guard caretRect.minY > 0 else { return }
        var lookup: UIView? = self
        while let superview = lookup?.superview {
            lookup = superview
            if lookup is UIScrollView { break }
        }
        guard let scrollView = lookup as? UIScrollView else { return }
        let caretY = scrollView.convert(caretRect.center, from: textView.coordinateSpace).y
        guard caretY.isFinite, caretY > 0 else { return }
        if caretY < scrollView.contentOffset.y {
            let acceptableMin = scrollView.contentOffset.y
            let shift = acceptableMin - caretY + 50
            var offset = scrollView.contentOffset
            offset.y -= shift
            offset.y = max(0, offset.y)
            scrollView.setContentOffset(offset, animated: true)
        } else if caretY > scrollView.contentOffset.y + scrollView.frame.height {
            let acceptableMax = scrollView.contentOffset.y + scrollView.frame.height
            let shift = caretY - acceptableMax + 50
            var offset = scrollView.contentOffset
            offset.y += shift
            scrollView.setContentOffset(offset, animated: true)
        }
    }

    func textViewDidEndEditing(_: UITextView) {
        cleanTextAttribute()
    }

    func cleanTextAttribute() {
        let text = mainTextEditor.text
        mainTextEditor.attributedText = nil
        mainTextEditor.text = text
        mainTextEditor.font = textParser.getFont()
    }

    func updateEditorHints() {
        mainTextEditor.executeFocusedUpdate { textView in
            defer { withMainActor(delay: 0.1) {
                self.keepSelecionInFocus(self.mainTextEditor)
            } }

            textView.font = textParser.getFont()

            if let text = textView.attributedText.mutableCopy() as? NSMutableAttributedString {
                if let limit = source?.instance.maxNoteTextLength,
                   limit < text.length
                {
                    text.addAttributes([
                        .backgroundColor: UIColor.systemRed.withAlphaComponent(0.25),
                    ], range: NSRange(location: limit, length: text.length - limit))
                    textView.attributedText = text
                } else {
                    text.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: text.length))
                    textView.attributedText = text
                }
            }
        }
    }
}
