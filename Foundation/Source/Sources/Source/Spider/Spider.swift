//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation
import Module
import ModuleBridge
import NetworkModule
import Storage

/*

 this class is designed to extract useful information from nested object returned from server

 eg:
 Note {
    user: User {                <- data!
        instance: Instance { }  <- data!
    }
    renote: Note { }            <- data!
    emoji: Emoji {}             <- data!
 }

 */

internal class Spider {
    let notes: KVStorage<Note>
    let users: KVStorage<User>

    let defaultHost: String

    init(notes: KVStorage<Note>, users: KVStorage<User>, defaultHost: String) {
        self.notes = notes
        self.users = users

        self.defaultHost = defaultHost
    }

    func spidering(_ object: Any?) {
        guard let object else { return }
        if let object = object as? [Any] {
            object.forEach { spidering($0) }
        } else {
            if let object = object as? NMNote {
                spidering(object.emojis)
                spidering(object.user)
                notes.write(.converting(object))
            }
            if let object = object as? NMUserLite {
                spidering(object.emojis)
                users.write(.converting(object, defaultHost: defaultHost))
            }
            if let object = object as? NMUserDetails {
                spidering(object.emojis)
                spidering(object.pinnedNotes)
                if let profile = UserProfile.converting(object, defaultHost: defaultHost) {
                    spidering(User.converting(profile))
                }
            }
            if let object = object as? NMInstance {
                spidering(object.emojis)
            }
            if let object = object as? NMNotification {
                spidering(object.user)
                spidering(object.note)
            }
        }
    }
}
