//
//  NoteOperationStrip+Share.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import LinkPresentation
import SDWebImage
import Source
import UIKit

extension NoteOperationStrip {
    @objc func shareButtonTapped() {
        debugPrint(#function)
        shareButton.shineAnimation()
        guard let source,
              let noteId,
              let note = source.notes.retain(noteId),
              let user = source.users.retain(note.userId)
        else { return }

        var shareItems = [Any]()
        var shareActivities = [UIActivity]()

        let activityItemMetadata = NoteShareItemSource(source: source, noteId: noteId)
        shareItems.append(activityItemMetadata)

        let copyText = Activity(
            title: "Copy Text",
            image: UIImage(systemName: "doc.on.doc")
        ) { _ in
            UIPasteboard.general.string = note.text
            presentMessage("Copied")
        }
        shareActivities.append(copyText)

        let openInBrowser = Activity(
            title: "Open In Browser",
            image: UIImage(systemName: "safari")
        ) { _ in
            guard let url = source.notes.retain(noteId)?.url
                ?? URL(string: "https://\(source.user.host)/notes/\(noteId)")
            else { return }
            UIApplication.shared.open(url)
        }
        shareActivities.append(openInBrowser)
        let copyLink = Activity(
            title: "Copy Link",
            image: UIImage(systemName: "doc.on.doc")
        ) { _ in
            guard let url = source.notes.retain(noteId)?.url
                ?? URL(string: "https://\(source.user.host)/notes/\(noteId)")
            else { return }
            UIPasteboard.general.string = url.absoluteString
            presentMessage("Copied")
        }
        shareActivities.append(copyLink)

        if activityItemMetadata.url?.host?.lowercased() != source.user.host.lowercased() {
            let openInBrowserWithUserInstance = Activity(
                title: "Open In Browser (\(source.user.host))",
                image: UIImage(systemName: "safari")
            ) { _ in
                guard let url = URL(string: "https://\(source.user.host)/notes/\(noteId)") else {
                    return
                }
                UIApplication.shared.open(url)
            }
            shareActivities.append(openInBrowserWithUserInstance)
            let copyLinkWithUserInstance = Activity(
                title: "Copy Link (\(source.user.host))",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                guard let url = URL(string: "https://\(source.user.host)/notes/\(noteId)") else {
                    return
                }
                UIPasteboard.general.string = url.absoluteString
                presentMessage("Copied")
            }
            shareActivities.append(copyLinkWithUserInstance)
        }

        let copyUsername = Activity(
            title: "Copy Username (\(user.absoluteUsername))",
            image: UIImage(systemName: "doc.on.doc")
        ) { _ in
            UIPasteboard.general.string = user.absoluteUsername
            presentMessage("Copied")
        }
        shareActivities.append(copyUsername)

        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: shareActivities
        )
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.permittedArrowDirections = []
            popoverController.sourceRect = CGRect(
                x: shareButton.bounds.midX,
                y: shareButton.bounds.midY,
                width: .zero,
                height: .zero
            )
        }
        parentViewController?.present(activityVC, animated: true)
    }
}

private class NoteShareItemSource: NSObject, UIActivityItemSource {
    var linkMetadata: LPLinkMetadata
    let noteId: NoteID
    weak var source: Source?

    let url: URL?

    init(linkMetadata: LPLinkMetadata = LPLinkMetadata(), source: Source, noteId: NoteID) {
        self.linkMetadata = linkMetadata
        self.source = source
        self.noteId = noteId

        url = source.notes.retain(noteId)?.url ?? URL(string: "https://\(source.user.host)/notes/\(noteId)")
    }

    func openInSafari() {
        if let url { UIApplication.shared.open(url) }
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        guard let source,
              let note = source.notes.retain(noteId),
              let user = source.users.retain(note.userId)
        else {
            return nil
        }

        linkMetadata.originalURL = url
        linkMetadata.url = url

        let parser = TextParser()
        let name = parser.trimToPlainText(from: user.name)
        let text = parser.trimToPlainText(from: note.text)

        var items = [String]()
        if text.count > 0 { items.append(text) }
        if !note.attachments.isEmpty { items.append("📎x\(note.attachments.count)") }

        let buildBody = items.joined(separator: " ")
        let build = if buildBody.isEmpty {
            "\(name)"
        } else {
            "\(name): \(buildBody)"
        }
        linkMetadata.title = build

        if let image = SDImageCache.shared.imageFromCache(forKey: user.avatarUrl) {
            linkMetadata.iconProvider = NSItemProvider(object: image)
        }

        return linkMetadata
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any { "" }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        linkMetadata.url
    }
}

private class Activity: UIActivity {
    var _activityTitle: String
    var _activityImage: UIImage?
    var activityItems = [Any]()
    var action: ([Any]) -> Void

    init(title: String, image: UIImage?, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        _activityImage = image
        action = performAction
        super.init()
    }

    override var activityTitle: String? {
        _activityTitle
    }

    override var activityImage: UIImage? {
        _activityImage
    }

    override var activityType: UIActivity.ActivityType {
        UIActivity.ActivityType(rawValue: String(describing: self))
    }

    override class var activityCategory: UIActivity.Category {
        .action
    }

    override func canPerform(withActivityItems _: [Any]) -> Bool {
        true
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }

    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
}
