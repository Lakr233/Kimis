//
//  Account.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/17.
//

import Combine
import Foundation
import Source

final class Account {
    let storeLocation = documentsDirectory
        .appendingPathComponent("Accounts")

    // store self sinker, not source.cancellable
    private var cancellable = Set<AnyCancellable>()

    static let shared = Account()
    private init() {
        try? FileManager.default.createDirectory(at: storeLocation, withIntermediateDirectories: true)
        cleanUp()
        if !activated.isEmpty { activate(receiptID: activated) }
        $source
            .receive(on: DispatchQueue.main)
            .sink { value in
                self.activated = value?.receiptId ?? ""
            }
            .store(in: &cancellable)

        // just make sure thing will update on macOS, not a fan controlling this behavior
        let timer = Timer(timeInterval: 300, repeats: true) { [weak self] _ in
            self?.requestStatusUpdate()
        }
        RunLoop.main.add(timer, forMode: .default)
    }

    @Published var source: Source?
    @Published var updated = CurrentValueSubject<Bool, Never>(true)

    @EncryptedCodableDefault(key: "wiki.qaq.accounts", defaultValue: .init())
    private var accounts: [LoginChallengeReceipt.ID: LoginChallengeReceipt] {
        didSet { updated.send(true) }
    }

    @UserDefault(key: "wiki.qaq.accounts.activated", defaultValue: "")
    private var activated: String {
        didSet { updated.send(true) }
    }

    var loginRequested: Bool {
        source == nil || accounts.isEmpty
    }

    func store(receipt: LoginChallengeReceipt) {
        assert(Thread.isMainThread)
        accounts[receipt.id] = receipt
    }

    func activate(receiptID: LoginChallengeReceipt.ID) {
        assert(Thread.isMainThread)
        deactivateCurrent()
        guard let receipt = accounts[receiptID] else {
            return
        }
        print("[*] activating account \(receipt.id)")
        let source = Source(withLoginChallengeRecipe: receipt, storageLocation: storeLocation)
        Publishers.CombineLatest($source, source.errorMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.resolveError(message: value.1, source: value.0)
            }
            .store(in: &source.cancellable)
        self.source = source
    }

    func resolveError(message: String?, source _: Source?) {
        guard let message else { return }
        print("[E] interface error: \(message)")
        presentError(message)
    }

    func deactivateCurrent() {
        if let source {
            source.destroy()
            self.source = nil
        }
    }

    func list() -> [LoginChallengeReceipt] {
        Array(accounts.values)
    }

    func delete(receiptID: LoginChallengeReceipt.ID) {
        assert(Thread.isMainThread)
        accounts.removeValue(forKey: receiptID)
        if source?.receiptId == receiptID { deactivateCurrent() }
    }

    private func cleanUp() {
        let contents = try? FileManager.default.contentsOfDirectory(atPath: storeLocation.path)
        guard let contents else { return }
        let read = accounts.values
            .map { Source.storeRoot(forReceipt: $0, atRoot: storeLocation) }
            .map(\.lastPathComponent)
        let set = Set<String>(read)
        for item in contents where !set.contains(item) {
            print("[*] cleaning up \(item)")
            try? FileManager.default.removeItem(at: storeLocation.appendingPathComponent(item))
        }
    }

    func requestStatusUpdate() {
        guard let source else { return }
        print("[*] Account request status update...")
        DispatchQueue.global().async {
            if !source.timeline.updating {
                source.timeline.requestUpdate(direction: .newer)
            }
            if !source.notifications.updating {
                source.notifications.fetchNotification(direction: .new)
            }
        }
    }
}
