//
//  NoteViewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/23.
//

import Combine
import Source
import UIKit

class NoteViewController: ViewController, RouterDatable {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "💬"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var associatedData: Any? {
        didSet {
            assert(oldValue == nil, "NoteViewController is bonded to one note per life")
            updateDataSource()
        }
    }

    var noteId: NoteID? {
        associatedData as? NoteID
    }

    @Published var trim: NoteID? = nil
    @Published var chain: [NoteID] = []
    @Published var main: NoteID? = nil
    @Published var replies: [NoteID] = []
    @Published var loading: Set<LoadingLocation> = []

    enum LoadingLocation: String {
        case head
        case bottom
    }

    var shouldScroll: Bool = true // scroll to note on load

    let progressIndicator = UIActivityIndicatorView()
    let progressCover = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.onSelect = { [weak self] noteId in
            self?.didSelect(noteId)
        }
        makeProgressCover()
        createPublisher()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAfterSent),
            name: .postSent,
            object: nil,
        )
    }

    let tableView = NoteTableView()

    func makeProgressCover() {
        progressIndicator.startAnimating()
        progressCover.backgroundColor = view.backgroundColor
        progressCover.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addSubview(progressCover)
        progressCover.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func hideProgress(delay: Double = 0.5) {
        withMainActor(delay: delay) {
            withUIKitAnimation(duration: 0.5) {
                self.progressCover.alpha = 0
            } completion: {
                self.progressCover.removeFromSuperview()
            }
        }
    }

    @objc func updateAfterSent(_ notification: Notification) {
        if let relatedNoteId = notification.object as? NoteID,
           main == noteId || chain.contains(relatedNoteId) || replies.contains(relatedNoteId)
        {
            withMainActor { [self] in
                updateDataSource(canFetch: true)
            }
        }
    }

    func updateDataSource(canFetch: Bool = true) {
        assert(Thread.isMainThread)

        trim = nil
        chain = []
        main = nil
        replies = []

        main = noteId
        trim = source?.notes.retain(noteId)?.replyId

        if let note = source?.notes.retain(main) {
            if let user = source?.users.retain(note.userId) {
                title = "💬 \(TextParser().trimToPlainText(from: user.name))"
            }
            hideProgress()
            findReplies()
            downloadReplies()
            DispatchQueue.global().async {
                let updated = self.source?.req.requestNote(withID: self.noteId) != nil
                if !updated {
                    presentError(L10n.text("Unable to load this note"))
                }
            }
        } else if canFetch {
            DispatchQueue.global().async {
                self.source?.req.requestNote(withID: self.noteId)
                withMainActor {
                    self.updateDataSource(canFetch: false)
                }
            }
        } else {
            presentError(L10n.text("Broken Note Data"))
        }
    }

    func createPublisher() {
        Publishers.CombineLatest4($trim, $chain, $main, $replies)
            .combineLatest($loading)
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .map { val -> [NoteCell.Context] in
                var firstBuild: [NoteCell.Context] = Self.buildContext(
                    trim: val.0.0,
                    chain: val.0.1,
                    main: val.0.2,
                    replies: val.0.3,
                )
                if val.1.contains(.head) {
                    if firstBuild.first?.kind == .moreHeader { firstBuild.removeFirst() }
                    firstBuild.insert(.init(kind: .separator), at: 0)
                    firstBuild.insert(NoteCell.Context(kind: .progress), at: 0)
                }
                return firstBuild
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.tableView.updatedSource.send(value)
                withMainActor(delay: 0.1) { // fuck you reload delay fuck!
                    if let note = self?.noteId, self?.shouldScroll ?? false {
                        if self?.tableView.scrollTo(note: note, animated: true) ?? false {
                            self?.shouldScroll = false
                        }
                    }
                }
            }
            .store(in: &cancellable)

        $loading
            .removeDuplicates()
            .sink { [weak self] value in
                self?.tableView.footerProgressWorkingJobs += value.contains(.bottom) ? 1 : -1
            }
            .store(in: &cancellable)

        source?.notesChange
            .filter { [weak self] output in
                guard let self else { return false }
                if trim == output { return true }
                if chain.contains(output) { return true }
                if main == output { return true }
                if replies.contains(output) { return true }
                return false
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateDataSource(canFetch: true)
            }
            .store(in: &cancellable)
    }

    static func buildContext(trim: NoteID?, chain: [NoteID], main: NoteID?, replies: [NoteID]) -> [NoteCell.Context] {
        var build = [NoteCell.Context]()
        if let trim {
            build.append(.init(kind: .moreHeader, noteId: trim, connectors: [.down]))
        }

        let chainCtx = chain.map {
            let ctx = NoteCell.Context(
                kind: .main,
                noteId: $0,
                connectors: [.up, .down],
            )
            ctx.disablePaddingAfter = true
            return ctx
        }
        if trim == nil {
            chainCtx.first?.connectors.remove(.up)
        }
        chainCtx.last?.disablePaddingAfter = false
        build.append(contentsOf: chainCtx)

        let fullCell = NoteCell.Context(kind: .full, noteId: main)
        build.append(fullCell)
        if !chainCtx.isEmpty {
            fullCell.connectors.insert(.up)
        }

        var repliesCtx = replies.map {
            let ctx = NoteCell.Context(
                kind: .replyPadded,
                noteId: $0,
                connectors: [.attach, .pass],
            )
            ctx.disablePaddingAfter = true
            return ctx
        }
        repliesCtx.sort { $0.noteId ?? "" < $1.noteId ?? "" }
        repliesCtx.last?.disablePaddingAfter = false
        repliesCtx.last?.connectors.remove(.pass)
        build.append(contentsOf: repliesCtx)

        return build
    }

    func findReplies() {
        guard let source, let noteId = trim else { return }
        guard let note = source.notes.retain(noteId) else {
            return
        }
        chain.insert(note.noteId, at: 0)
        trim = note.replyId
        if trim != nil { findReplies() }
    }

    func downloadReplies() {
        loading.insert(.bottom)
        DispatchQueue.global().async { [weak self] in
            let replies = self?.source?.req.requestNoteReplies(withID: self?.main)
            self?.replies = replies?.map(\.noteId) ?? []
            withMainActor { [weak self] in
                self?.loading.remove(.bottom)
            }
        }
    }

    func didSelect(_ note: NoteID) {
        guard note != main else { return }
        assert(Thread.isMainThread)
        if let trim, trim == note {
            print("[*] requesting new header note \(trim)")
            loading.insert(.head)
            DispatchQueue.global().async { [weak self] in
                self?.source?.req.requestNote(withID: trim)
                withMainActor { [weak self] in
                    self?.loading.remove(.head)
                    self?.findReplies()
                }
            }
        } else {
            ControllerRouting.pushing(tag: .note, referencer: self, associatedData: note)
        }
    }
}
