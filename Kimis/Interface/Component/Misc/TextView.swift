//
//  TextView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import SubviewAttachingTextView
import UIKit

class TextView: SubviewAttachingTextView, UITextViewDelegate {
    let allowEdit: Bool
    let allowSelection: Bool
    let allowTapOnLink: Bool

    override var attributedText: NSAttributedString! {
        get { super.attributedText }
        set {
            var text = newValue
            if !allowTapOnLink, let mutable = text?.mutableCopy() as? NSMutableAttributedString {
                mutable.removeAttribute(.link, range: mutable.full)
                text = mutable
            }
            super.attributedText = text
        }
    }

    static func noneInteractive() -> TextView {
        let view = TextView(editable: false, selectable: false, disableLink: true)
        view.isUserInteractionEnabled = false
        return view
    }

    init(editable: Bool = true, selectable: Bool = true, disableLink: Bool = false) {
        allowEdit = editable
        allowSelection = selectable
        allowTapOnLink = !disableLink

        super.init(frame: .zero, textContainer: nil)

        delegate = self

        tintColor = .accent

        linkTextAttributes = [:]
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        textContainer.lineFragmentPadding = .zero
        textAlignment = .natural
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineBreakMode = .byTruncatingTail
        isScrollEnabled = false

        textDragInteraction?.isEnabled = false

        isEditable = editable
        isSelectable = true
        isScrollEnabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func textViewDidChangeSelection(_ textView: UITextView) {
        if !allowSelection { textView.selectedTextRange = nil }
    }

    // purpose: disable selection, allow links
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }

        // respond to edit or selection caret if configured with allow
        if allowEdit || allowSelection { return true }

        // check the touched point is valid to text and text is not empty
        guard attributedText.length > 0,
              let position = closestPosition(to: point)
        else { return false }

        // validate loc in text
        let loc = offset(from: beginningOfDocument, to: position)
        guard loc < attributedText.length, loc >= 0 else { return false }

        // check if contains attr link
        guard attributedText.attribute(.link, at: loc, effectiveRange: nil) != nil
        else { return false }

        // make sure closestPosition isn't return the line breaker
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        var hitOnGlyph = false
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, _, stop in
            if usedRect.contains(point) {
                hitOnGlyph = true
                stop.pointee = true
            }
        }
        // touched location dose not contain a glyph
        return hitOnGlyph
    }

    func textView(_: UITextView, shouldInteractWith URL: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
        guard allowTapOnLink else { return false }
        ControllerRouting.pushing(deepLink: URL.absoluteString, referencer: self)
        return false
    }
}

extension UITextView {
    func setSelectionIfPossible(_ selection: NSRange?) {
        defer { delegate?.textViewDidChangeSelection?(self) }
        guard let selection, selectedRange != selection else { return }
        guard selection.location > 0,
              selection.location + selection.length <= attributedText.length
        else {
            print(
                """
                [!] UITextView failed to set selection \(hashValue)
                    location \(selection.location) length \(selection.length)
                    selection end at \(selection.location + selection.length)
                    attr text length \(attributedText.length)
                """
            )
            return
        }
        selectedRange = selection
    }

    func executeFocusedUpdate(_ executing: (UITextView) -> Void) {
        var selection = selectedRange
        let originLength = attributedText.length
        defer {
            let modifiedLength = attributedText.length
            let lengthFixup = modifiedLength - originLength
            if lengthFixup != 0 { // text length modified!
                print("[*] UITextView attr text length changed \(originLength) -> \(modifiedLength)")
                selection.location += lengthFixup
                selection.length = 0
            }
            setSelectionIfPossible(selection)
        }
        executing(self)
    }
}

class VerticallyCenteredTextView: TextView {
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
}
