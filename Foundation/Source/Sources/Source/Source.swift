import Combine
import CommonCrypto
import Foundation
import Module
import Network
import SQLite
import Storage

@_exported import Module

private let updateThrottle: TimeInterval = 10

public class Source: ObservableObject, Identifiable, Equatable {
    public var id: UUID = .init()

    public var host: URL { network.base }

    public var receiptId: String { receipt.id }
    public let receipt: LoginChallengeReceipt

    public let storeRoot: URL

    public let network: Network
    public private(set) var req: NetworkWrapper!

    let database: Connection
    let spider: Spider

    public let properties: Properties

    public let notes: KVStorage<Note>
    public let notesChange = PassthroughSubject<Note.ID, Never>()
    public let users: KVStorage<User>

    public let errorMessage: PassthroughSubject<String, Never> = .init()
    private let errorMessageQueue = DispatchQueue(label: "wiki.qaq.source.error.message")
    private let errorMessageThrottle = TimeInterval(3)
    private var errorMessageHistory = [String: Date]()

    @Published public private(set) var user: UserProfile
    @PropertyStorage
    var userProfile: UserProfile {
        didSet {
            nextUserProfileUpdateDate = Date().addingTimeInterval(updateThrottle)
            user = userProfile
        }
    }

    var nextUserProfileUpdateDate: Date = .init(timeIntervalSince1970: 0)

    @Published public private(set) var instance: Instance
    @PropertyStorage
    var instanceProfile: Instance {
        didSet {
            nextInstanceProfileUpdateDate = Date().addingTimeInterval(updateThrottle)
            instance = instanceProfile
        }
    }

    var nextInstanceProfileUpdateDate: Date = .init(timeIntervalSince1970: 0)

    @PropertyStorage
    public var emojis: [String: Emoji] // without ::, eg: ytm_smile

    public var timeline: TimelineSource!
    public var trending: TrendingSource!
    public var bookmark: BookmarkSource!
    public var notifications: NotificationSource!

    public var cancellable = Set<AnyCancellable>()

    public convenience init(withLoginChallengeRecipe receipt: LoginChallengeReceipt, storageLocation: URL) {
        guard let base = URL(string: "https://\(receipt.host)") else {
            fatalError()
        }
        self.init(withLoginChallengeRecipe: receipt, baseEndpoint: base, storageLocation: storageLocation)
    }

    public init(withLoginChallengeRecipe receipt: LoginChallengeReceipt, baseEndpoint base: URL, storageLocation: URL) {
        assert(Thread.isMainThread)

        print("[*] initializing source for \(receipt.universalIdentifier)")

        self.receipt = receipt

        network = .init(base: base, credential: receipt.token)

        let storage = Self.storeRoot(forReceipt: receipt, atRoot: storageLocation)
        try? FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)

        storeRoot = storage

        let databaseLocation = storage
            .appendingPathComponent("main.db")
        do {
            let database = try Connection(databaseLocation.path)
            self.database = database
        } catch {
            fatalError(error.localizedDescription)
        }

        notes = KVStorage(
            dbConnection: database,
            validating: Note(noteId: "__0xaa55__"),
            updating: notesChange
        )
        users = KVStorage(
            dbConnection: database,
            validating: User(userId: "__0xaa55__"),
            updating: nil
        )

        let propertiesLocation = storage
            .appendingPathComponent("properties.list")
        properties = Properties(storeLocation: propertiesLocation)

        _userProfile = .init(key: .userProfile, defaultValue: .init(), storage: properties, notify: nil)
        _instanceProfile = .init(key: .instanceProfile, defaultValue: .init(), storage: properties, notify: nil)
        _emojis = .init(key: .instanceEmoji, defaultValue: .init(), storage: properties, notify: nil)

        _user = .init(wrappedValue: _userProfile.wrappedValue)
        _instance = .init(wrappedValue: _instanceProfile.wrappedValue)

        spider = .init(notes: notes, users: users, defaultHost: receipt.host)

        timeline = .init(context: self)
        trending = .init(context: self)
        bookmark = .init(context: self)
        notifications = .init(context: self)

        req = .init(ctx: self)

        network.errorMessage
            .sink { [weak self] value in
                self?.prepareErrorMessage(value)
            }
            .store(in: &cancellable)

        DispatchQueue.global().async {
            self.populateUserInfo()
        }
        DispatchQueue.global().async {
            self.populateInstanceInfo()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.timeline.requestUpdate(direction: .newer)
            self.bookmark.reloadBookmark()
            self.notifications.fetchNotification(direction: .new)
        }
    }

    public static func == (lhs: Source, rhs: Source) -> Bool {
        lhs.id == rhs.id
    }

    deinit {
        print("[*] deinit called for \(receipt.universalIdentifier)")
        cancellable.forEach { $0.cancel() }
        cancellable.removeAll()
    }

    public func destroy() {
        print("[*] destroying data source for \(receipt.universalIdentifier)")
        network.destroy()
        cancellable.forEach { $0.cancel() }
        cancellable = []
    }
}

public extension Source {
    func populateUserInfo(forceUpdate: Bool = false) {
        assert(!Thread.isMainThread)
        if !forceUpdate, nextUserProfileUpdateDate.timeIntervalSinceNow > 0 {
            return
        }
        let result = network.requestForUserDetails(userIdOrName: receipt.universalIdentifier)
        spider.spidering(result.extracted)
        spider.spidering(result.result)
        guard let rawProfile = result.result,
              let profile = UserProfile.converting(rawProfile, defaultHost: receipt.host)
        else {
            return
        }
        print("[*] user profile updated")
        userProfile = profile
    }

    func populateInstanceInfo(forceUpdate: Bool = false) {
        assert(!Thread.isMainThread)
        defer { populateEmojiItems() }
        if !forceUpdate, nextInstanceProfileUpdateDate.timeIntervalSinceNow > 0 {
            return
        }
        let result = network.requestForInstanceInfo()
        spider.spidering(result)
        guard let object = result,
              let instance = Instance.converting(object)
        else {
            return
        }
        print("[*] instance profile updated")
        instanceProfile = instance
    }

    func populateEmojiItems() {
        assert(!Thread.isMainThread)
        guard let downloadEmojis = network.requestForEmojis() else {
            return
        }
        var buildEmojis = [String: Emoji]()
        for item in downloadEmojis {
            buildEmojis[item.name] = .converting(item)
        }
        print("[*] updating \(downloadEmojis.count) emojis")
        emojis = buildEmojis
    }

    func isTextMuted(text: String) -> Bool {
        for word in userProfile.mutedWords {
            if text.contains(word) { return true }
        }
        return false
    }

    func isNoteMuted(noteId: String) -> Bool {
        let muted = _isNoteMuted(noteId: noteId)
        #if DEBUG
            if muted {
                let note = notes.retain(noteId)
                let user = users.retain(note?.userId)
                print("🔇 [\(noteId)] \(user?.name ?? ""): \(note?.text ?? notes.retain(note?.renoteId)?.text ?? "?")")
            }
        #endif
        return muted
    }

    private func _isNoteMuted(noteId: String) -> Bool {
        guard let note = notes.retain(noteId) else { return true }
        if note.userId == receipt.accountId { return false }
        if isTextMuted(text: note.text) { return true }
        guard let user = users.retain(note.userId) else { return true }
        if isTextMuted(text: user.name) { return true }
        if let renote = note.renoteId {
            guard let note = notes.retain(renote) else { return true }
            if note.userId == receipt.accountId { return false }
            if isTextMuted(text: note.text) { return true }
            guard let user = users.retain(note.userId) else { return true }
            if isTextMuted(text: user.name) { return true }
        }
        return false
    }
}

public extension Source {
    static func storeRoot(forReceipt receipt: LoginChallengeReceipt, atRoot storeLocation: URL) -> URL {
        storeLocation.appendingPathComponent(receipt.universalIdentifier.sha1())
    }
}

private extension String {
    func sha1() -> String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

extension Source {
    func prepareErrorMessage(_ error: String) {
        errorMessageQueue.async { [self] in
            var shouldPresentMessage = false
            if let previousDate = errorMessageHistory[error] {
                if previousDate.timeIntervalSinceNow < -errorMessageThrottle {
                    shouldPresentMessage = true
                }
            } else {
                shouldPresentMessage = true
            }
            if shouldPresentMessage {
                errorMessageHistory[error] = Date()
                errorMessage.send(error)
            }
        }
    }
}
