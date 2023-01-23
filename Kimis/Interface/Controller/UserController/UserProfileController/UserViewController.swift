//
//  UserViewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import Combine
import MorphingLabel
import Source
import UIKit

extension Notification.Name {
    static let requestUserProfileUpdate = Notification.Name("wiki.qaq.requestUserProfileUpdate")
}

class UserViewController: ViewController, RouterDatable {
    var isLoadingProfile: Bool = false {
        didSet {
            if isLoadingProfile {
                userView.status = .loading
            } else if userProfile == nil {
                userView.status = .failure
            } else {
                userView.status = .normal
            }
        }
    }

    var isLoadingNotes: Bool { loadingNotesTicket != nil }
    var loadingNotesTicket: UUID?

    var userProfile: UserProfile? {
        didSet { if oldValue != userProfile {
            userView.profile = userProfile
            if let name = userProfile?.name {
                title = "😶 \(TextParser().trimToPlainText(from: name))"
            } else {
                title = "😶"
            }
        } }
    }

    var animatable: Bool = false

    @Published var pinnedList: [NoteID] = []
    @Published var notesList: [NoteID] = []

    enum FetchEndpoint: String {
        case notes
        case notesWithReplies
        case media
    }

    var fetchEndpoint: FetchEndpoint = .notes {
        didSet {
            guard oldValue != fetchEndpoint else { return }
            updateEndpointButtons()
            notesList = []
            updateNotes(force: true)
        }
    }

    var userView = ProfileView()
    let tableView = NoteTableView()

    override var title: String? {
        get { titleTextView.text }
        set {
            super.title = newValue
            titleTextView.text = newValue
        }
    }

    let titleView = UIView()
    let titleTextView = LTMorphingLabel()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "😶"
        createNotePublisher()

        NotificationCenter.default.publisher(for: .requestUserProfileUpdate)
            .filter { [weak self] notification in
                guard let self else { return false }
                guard !self.userHandler.isEmpty else { return false }
                guard let mathcer = notification.object as? String else {
                    assertionFailure()
                    return false
                }
                let isCurrentUser = false
                    || mathcer == self.userHandler
                    || mathcer == self.userProfile?.userId
                    || mathcer == self.userProfile?.absoluteUsername
                return isCurrentUser
            }
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performReload()
            }
            .store(in: &cancellable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var associatedData: Any? {
        didSet {
            assert(oldValue == nil)
            userView.representUser = userHandler
        }
    }

    var userHandler: String { associatedData as? String ?? "" }

    override func viewDidLoad() {
        super.viewDidLoad()

        withMainActor(delay: 0.5) { self.animatable = true }

        navigationItem.titleView = titleView
        titleView.addSubview(titleTextView)
        titleTextView.textAlignment = .center
        titleTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.clipsToBounds = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.tableHeaderView = userView
        tableView.$scrollLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.didScroll(toPosition: value)
            }
            .store(in: &cancellable)

        userView.backgroundColor = view.backgroundColor
        userView.$contentHeight
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                let update = {
                    self?.tableView.tableHeaderView?.frame.size.height = height
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                }
                if self?.animatable ?? false {
                    withUIKitAnimation { update() }
                } else {
                    update()
                }
            }
            .store(in: &cancellable)

        updateEndpointButtons()
        userView.segmentNoteButton.tapped = { [weak self] in
            self?.fetchEndpoint = .notes
            self?.updateNotes()
        }
        userView.segmentRepliesButton.tapped = { [weak self] in
            self?.fetchEndpoint = .notesWithReplies
            self?.updateNotes()
        }
        userView.segmentMediaButton.tapped = { [weak self] in
            self?.fetchEndpoint = .media
            self?.updateNotes()
        }

        userView.retryButton.addTarget(self, action: #selector(performReload), for: .touchUpInside)
        userView.representUser = userHandler

        performReload()
        didScroll(toPosition: .zero)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        userView.layoutSubviews()
    }

    func reset() {
        userProfile = nil
        pinnedList = []
        notesList = []
    }

    @objc func performReload() {
        performFetcherUpdate()
    }

    func updateEndpointButtons() {
        userView.segmentNoteButton.highlight = false
        userView.segmentRepliesButton.highlight = false
        userView.segmentMediaButton.highlight = false
        switch fetchEndpoint {
        case .notes: userView.segmentNoteButton.highlight = true
        case .notesWithReplies: userView.segmentRepliesButton.highlight = true
        case .media: userView.segmentMediaButton.highlight = true
        }
    }

    func determineLocalProfileIfPossible() -> UserProfile? {
        nil
    }

    static func reload(userId: UserID) {
        NotificationCenter.default.post(name: .requestUserProfileUpdate, object: userId)
    }
}
