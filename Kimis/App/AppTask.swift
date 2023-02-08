//
//  AppDelegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import BackgroundTasks
import Foundation
import UIKit

enum AppTask: String, CaseIterable, Codable {
    static let queue = DispatchQueue(label: "wiki.qaq.bgtask")

    // MARK: Fetch Notification

    case fetchNotifications = "bgfetch.notifications"
    static func scheduleFetchNotifications() {
        let request = BGAppRefreshTaskRequest(identifier: AppTask.fetchNotifications.rawValue)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[*] success fully scheduled task \(AppTask.fetchNotifications.rawValue)")
        } catch {
            print("[?] could not schedule app refresh: \(error)")
        }
    }

    static func handleFetchNotifications(task: BGAppRefreshTask) {
        assert(!Thread.isMainThread)
        print("[*] background task started for \(#function)")
        updateAndPostNotifications()
        task.setTaskCompleted(success: true)
    }
}

private extension AppTask {
    static func updateAndPostNotifications() {
        guard let source = Account.shared.source else {
            return
        }
        let sem = DispatchSemaphore(value: 0)
        source.notifications.fetchNotification(direction: .new) {
            sem.signal()
        }
        sem.wait()
        let notifications = source.notifications.obtainPendingNotificaitonsForPost()
        source.notifications.markPosted()

        print("[*] preparing \(notifications.count) notifications")
        let parser = TextParser()

        for notification in notifications {
            let user = source.users.retain(notification.userId)
                ?? source.users.retain(source.notes.retain(notification.noteId)?.userId)
                ?? .unavailable

            let noteBody = NSMutableAttributedString()
            if let note = source.notes.retain(notification.noteId) {
                let text = parser.compileNoteBody(withNote: note)
                noteBody.append(text)
                let attachmentCount = note.attachments.count
                if attachmentCount > 0 { noteBody.append(.init(string: "📎x\(attachmentCount)")) }
                if note.text.isEmpty,
                   let renoteId = note.renoteId,
                   let renote = source.notes.retain(renoteId)
                {
                    let body = parser.compileNoteBody(withNote: renote)
                    noteBody.append(body)
                }
            }

            let content = UNMutableNotificationContent()
            content.title = "\(parser.trimToPlainText(from: user.name)) \(notification.type.title)"
                .capitalized
            content.body = noteBody.string
            content.sound = .default
            print(
                """
                [*] requested notificaiton
                    \(content.title)
                    \(content.subtitle)
                    \(content.threadIdentifier)
                """
            )
            if let userAvatar = user.avatarUrl,
               let avatarUrl = URL(string: userAvatar),
               let attachment = try? UNNotificationAttachment(identifier: user.absoluteUsername, url: avatarUrl)
            {
                content.attachments.append(attachment)
            }
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
