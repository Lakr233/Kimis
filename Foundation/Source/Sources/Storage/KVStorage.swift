import Combine
import Foundation
import LRUCache
import SQLite

public class KVStorage<T: Codable & Identifiable & Equatable> where T.ID == String {
    let db: Connection
    let table: Table
    let id = Expression<String>("id")
    let content = Expression<Data>("content")

    let publisher: PassthroughSubject<T.ID, Never>?

    let cahce: LRUCache<T.ID, T>

    public init(dbConnection: Connection, validating: T, updating: PassthroughSubject<T.ID, Never>?, caching: Int = 512) {
        db = dbConnection
        let name = "kv_" + String(describing: T.self)
            .components(separatedBy: .alphanumerics.inverted)
            .joined()
            .lowercased()
        table = Table(name)
        cahce = .init(countLimit: caching)
        publisher = updating

        defer { print("[*] key value storage for \(T.self) completed setup with table \(name)") }

        do {
            try db.run(table.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(content)
            })
            try test(with: validating)
        } catch {
            print("[&] preflight test failed, recreating table \(name)")
            _ = try? db.run(table.drop(ifExists: true))
            do {
                try db.run(table.create(ifNotExists: true) { t in
                    t.column(id, primaryKey: true)
                    t.column(content)
                })
                try test(with: validating)
            } catch {
                assertionFailure()
            }
        }
    }

    private func test(with object: T) throws {
        delete(object.id)
        guard retain(object.id) == nil else { throw NSError() }
        write(object, diff: false)
        guard retain(object.id) == object else { throw NSError() }
        delete(object.id)
        guard retain(object.id) == nil else { throw NSError() }

        print("[*] database test passed")
    }

    public func write(_ object: T?, diff: Bool = true) {
        guard let object else { return }
        if diff, let orig = cahce.value(forKey: object.id), object == orig {
            return
        }
        cahce.setValue(object, forKey: object.id)
        do {
            let data = try encoder.encode(object)
            try db.run(table.insert(or: .replace, id <- object.id, content <- data))
        } catch {
            print(error.localizedDescription)
            return
        }
        publisher?.send(object.id)
    }

    public func retain(_ id: T.ID?, cold: Bool = false) -> T? {
        guard let id else { return nil }
        if !cold, let object = cahce.value(forKey: id) {
            return object
        }
        var result: T?
        do {
            for item in try db.prepare(table.filter(id == self.id)) {
                let content = item[content]
                let object = try decoder.decode(T.self, from: content)
                result = object
            }
        } catch {
            print("[E] \(self) \(#function) \(id) \(error.localizedDescription)")
        }
        assert(result == nil || result?.id == id)
        return result
    }

    public func delete(_ id: T.ID) {
        cahce.removeValue(forKey: id)
        do {
            try db.run(table.filter(id == self.id).delete())
        } catch {
            print(error.localizedDescription)
        }
        publisher?.send(id)
    }

    public func searchAsText(keyword: String) -> [T.ID] {
        assert(!Thread.isMainThread)
        guard let iterator = try? db.prepare(table) else { return [] }
        var result: Set<T.ID> = []
        for record in iterator {
            let id = record[id]
            let data = record[content]
            guard let str = String(data: data, encoding: .utf8) else { continue }
            if str.contains(keyword) { result.insert(id) }
        }
        return Array(result)
    }
}
