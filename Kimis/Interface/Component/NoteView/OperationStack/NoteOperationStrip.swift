//
//  NoteCell+OperationStack.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/19.
//

import Combine
import Source
import UIKit

class NoteOperationStrip: UIView {
    var noteId: NoteID? { didSet { updateDataSource() } }

    static let contentHeight: CGFloat = 24
    let buttonSize = CGSize(width: 20, height: 20)
    static let buttonColor = UIColor.systemGray.withAlphaComponent(0.65)

    @propertyWrapper
    struct OperationButton {
        var wrappedValue = TapAreaEnlargedButton()

        init(icon: UIImage) {
            wrappedValue.defaultButton(icon: icon)

            wrappedValue.tintColor = buttonColor

            let hover = UIHoverGestureRecognizer(target: wrappedValue, action: #selector(TapAreaEnlargedButton.buttonHoverAnimation(_:)))
            wrappedValue.addGestureRecognizer(hover)
        }
    }

    @OperationButton(icon: .fluent(.comment_arrow_left))
    var replyButton: TapAreaEnlargedButton

    @OperationButton(icon: .fluent(.square_arrow_forward))
    var renoteButton: TapAreaEnlargedButton

    // reaction button could change
    private let reactButtonAddIcon = UIImage.fluent(.emoji_add)
    private let reactButtonDeleteIcon = UIImage.fluent(.subtract_square)
    @OperationButton
    var reactButton: TapAreaEnlargedButton

    @OperationButton(icon: .fluent(.share_ios))
    var shareButton: TapAreaEnlargedButton

    @OperationButton(icon: .fluent(.more_horizontal))
    var moreButton: TapAreaEnlargedButton

    var maxWidth: CGFloat = 400 {
        didSet { setNeedsLayout() }
    }

    var buttons: [UIButton] {
        [
            replyButton,
            renoteButton,
            reactButton,
            shareButton,
            moreButton,
        ]
    }

    let reactionIndicator = UIActivityIndicatorView()
    let moreOptionIndicator = UIActivityIndicatorView()
    let moreButtonMenuPresenter = UIButton() // invisible but will work
    let moreButtonInteractionDelegate = MoreButtonInteractionDelegate()

    var associatedControllers: [UIViewController] = []

    weak var source: Source? = Account.shared.source
    var cancellable: Set<AnyCancellable> = []

    init() {
        _reactButton = .init(icon: reactButtonAddIcon)

        super.init(frame: .zero)

        addSubview(moreButtonMenuPresenter)
        addSubviews(buttons)

        let moreButtonInteraction = UIContextMenuInteraction(delegate: moreButtonInteractionDelegate)
        moreButtonMenuPresenter.addInteraction(moreButtonInteraction)

        addSubview(reactionIndicator)
        addSubview(moreOptionIndicator)

        restoreDefaultAppearance()

        replyButton.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        renoteButton.addTarget(self, action: #selector(renoteButtonTapped), for: .touchUpInside)
        reactButton.addTarget(self, action: #selector(reactButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

        source?.notesChange
            .filter { [weak self] value in
                self?.noteId != nil && value == self?.noteId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateDataSource() }
            .store(in: &cancellable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let this = self
        let bounds = this.bounds

        var width = bounds.width
        if width > maxWidth { width = maxWidth }

        let spaceDistribute = (width - CGFloat(buttons.count) * buttonSize.width) / 4
        for (idx, button) in buttons.enumerated() {
            button.frame = CGRect(
                x: CGFloat(idx) * (buttonSize.width + spaceDistribute),
                y: 0,
                width: buttonSize.width,
                height: buttonSize.height
            )
        }

        reactionIndicator.size = reactionIndicator.intrinsicContentSize
        reactionIndicator.center = reactButton.center
        moreOptionIndicator.size = moreOptionIndicator.intrinsicContentSize
        moreOptionIndicator.center = moreButton.center

        moreButtonMenuPresenter.frame = moreButton.frame
    }

    func restoreDefaultAppearance() {
        reactButton.setImage(reactButtonAddIcon, for: .normal)
        reactButton.alpha = 1
        reactButton.isUserInteractionEnabled = true
        reactButton.isPointerInteractionEnabled = true

        reactionIndicator.isHidden = true
        reactionIndicator.stopAnimating()
        moreOptionIndicator.isHidden = true
        moreOptionIndicator.stopAnimating()
        associatedControllers.forEach { $0.dismiss(animated: true) }
        associatedControllers = []
    }

    var note: Note? {
        source?.notes.retain(noteId)
    }

    func updateDataSource() {
        restoreDefaultAppearance()
        moreButtonInteractionDelegate.noteId = nil

        guard let note else { return }
        moreButtonInteractionDelegate.noteId = note.noteId

        // reaction button could change
        if !note.userReaction.isEmpty {
            reactButton.setImage(reactButtonDeleteIcon, for: .normal)
        }
    }
}
