//
//  OperationStack+More.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import Source
import UIKit

extension NoteOperationStrip {
    @objc func moreButtonTapped() {
        debugPrint(#function)
        moreButton.shineAnimation()
        guard let noteId, let source else { return }
        fetchNoteStateAndPresentMenu(source: source, onNote: noteId)
    }

    private func fetchNoteStateAndPresentMenu(source: Source, onNote note: NoteID) {
        startProgressIndicator()
        DispatchQueue.global().async { [weak self] in
            defer { withMainActor {
                self?.stopProgressIndicator()
                self?.moreButtonMenuPresenter.presentMenu()
            } }
            let state = source.req.requestNoteState(withID: note)
            print("[*] note state \(state)")
            self?.moreButtonInteractionDelegate.noteId = note
            self?.moreButtonInteractionDelegate.noteState = state
            self?.moreButtonInteractionDelegate.anchor = self?.moreButtonMenuPresenter
        }
    }

    private func startProgressIndicator() {
        moreOptionIndicator.isHidden = false
        moreOptionIndicator.alpha = 1
        moreOptionIndicator.startAnimating()
        moreButton.alpha = 0
        moreButton.isUserInteractionEnabled = false
    }

    private func stopProgressIndicator() {
        moreOptionIndicator.isHidden = true
        moreOptionIndicator.alpha = 0
        moreOptionIndicator.stopAnimating()
        moreButton.alpha = 1
        moreButton.isUserInteractionEnabled = true
    }
}

extension NoteOperationStrip {
    class MoreButtonInteractionDelegate: NSObject, UIContextMenuInteractionDelegate {
        weak var source: Source? = Account.shared.source

        var noteId: NoteID? { didSet {
            noteState = nil
            anchor = nil
        } }
        var noteState: Source.NetworkWrapper.NoteState?
        weak var anchor: UIView?

        func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let anchor else { return nil }
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            parameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: 0)
            let preview = UITargetedPreview(view: anchor, parameters: parameters)
            return preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            guard let source, let note = source.notes.retain(noteId), let noteState else { return nil }
            var actions = [[UIAction]]()
            if noteState.isFavorited {
                actions.append([
                    UIAction(title: "Remove Favorited", image: .init(systemName: "trash")) { [weak self] _ in
                        let alert = UIAlertController(title: "⏳", message: "Sending Request", preferredStyle: .alert)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                alert.dismiss(animated: true)
                            } }
                            source.req.requestNoteRemoveFavorite(note: note.noteId)
                        }
                        self?.anchor?.parentViewController?.present(alert, animated: true)
                    },
                ])
            } else {
                actions.append([
                    UIAction(title: "Add Favorite", image: .init(systemName: "star")) { [weak self] _ in
                        let alert = UIAlertController(title: "⏳", message: "Sending Request", preferredStyle: .alert)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                alert.dismiss(animated: true)
                            } }
                            source.req.requestNoteAddFavorite(note: note.noteId)
                        }
                        self?.anchor?.parentViewController?.present(alert, animated: true)
                    },
                ])
            }
            if note.userId != source.user.userId {
                actions.append([
                    UIAction(title: "Report Abuse", image: .init(systemName: "exclamationmark.bubble"), attributes: .destructive) { [weak self] _ in
                        let alert = UIAlertController(title: "⚠️", message: "Are you sure you want to report this note?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in
                            alert.dismiss(animated: true) {
                                let alert = UIAlertController(title: "⏳", message: "Sending Request", preferredStyle: .alert)
                                DispatchQueue.global().async {
                                    defer { withMainActor {
                                        alert.dismiss(animated: true)
                                    } }
                                    source.req.requestForReportAbuse(note: note.noteId)
                                }
                                self?.anchor?.parentViewController?.present(alert, animated: true)
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self?.anchor?.parentViewController?.present(alert, animated: true)
                    },
                ])
            }
            if note.userId == source.user.userId {
                actions.append([
                    UIAction(title: "Delete", image: .init(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                        let alert = UIAlertController(title: "⚠️", message: "Are you sure you want to delete this note? All reply or renote with/within this note will also be deleted.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                            alert.dismiss(animated: true) {
                                let alert = UIAlertController(title: "⏳", message: "Sending Request", preferredStyle: .alert)
                                DispatchQueue.global().async {
                                    defer { withMainActor {
                                        alert.dismiss(animated: true)
                                    } }
                                    source.req.requestNoteDelete(withId: note.noteId)
                                }
                                self?.anchor?.parentViewController?.present(alert, animated: true)
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self?.anchor?.parentViewController?.present(alert, animated: true)
                    },
                ])
            }

            return .init(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: actions.map { actionGroup -> UIMenu in
                    UIMenu(options: .displayInline, children: actionGroup)
                })
            }
        }
    }
}
