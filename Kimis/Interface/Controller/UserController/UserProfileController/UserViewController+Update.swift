//
//  UserViewController+Update.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import Foundation
import Network
import Source

extension UserViewController {
    func performFetcherUpdate() {
        assert(Thread.isMainThread)
        guard !isLoadingProfile else { return }
        isLoadingProfile = true
        reset()
        DispatchQueue.global().async {
            defer { withMainActor { self.isLoadingProfile = false } }
            var profile: UserProfile
            if let p = self.determineLocalProfileIfPossible() {
                profile = p
            } else if let p = self.source?.req.requestForUserProfile(usingHandler: self.userHandler) {
                profile = p
            } else {
                return
            }
            print("[*] user profile for \(self.userHandler) updated")
            DispatchQueue.main.sync {
                self.userProfile = profile
                self.pinnedList = profile.pinnedNoteIds
                self.notesList = []
                self.updateNotes()
            }
        }
    }

    func updateNotes(force: Bool = false) {
        guard !isLoadingNotes || force else { return }
        guard let profile = userProfile else { return }
        let ticket = UUID()
        loadingNotesTicket = ticket
        tableView.footerProgressWorkingJobs += 1
        DispatchQueue.global().async {
            defer { withMainActor {
                if self.loadingNotesTicket == ticket {
                    self.loadingNotesTicket = nil
                }
                self.tableView.footerProgressWorkingJobs -= 1
            } }
            let type: Network.UserNoteFetchType
            switch self.fetchEndpoint {
            case .notes: type = .notes
            case .notesWithReplies: type = .replies
            case .media: type = .attachments
            }
            let notes = self.source?.req.requestForUserNotes(
                userHandler: profile.userId,
                type: type,
                untilId: self.notesList.last
            )
            guard let notes else { return }
            var filter = Set<NoteID>(self.notesList)
            let sorted = notes
                .compactMap { self.source?.notes.retain($0) }
                .sorted { $0.date > $1.date }
                .map(\.noteId)
                .filter {
                    if filter.contains($0) { return false }
                    filter.insert($0)
                    return true
                }
            DispatchQueue.main.sync {
                self.notesList.append(contentsOf: sorted)
            }
        }
    }
}
