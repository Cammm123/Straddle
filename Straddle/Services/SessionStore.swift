import Combine
import Foundation

enum StoreError: LocalizedError, Equatable {
    case createDirectory(String)
    case encode(String)
    case write(String)
    case read(String)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .createDirectory(let message): "Could not create local storage: \(message)"
        case .encode(let message): "Could not encode sessions: \(message)"
        case .write(let message): "Could not save sessions: \(message)"
        case .read(let message): "Could not read sessions: \(message)"
        case .decode(let message): "The sessions file is invalid: \(message)"
        }
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [PokerSession] = []
    @Published var lastError: StoreError?

    let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil, fileManager: FileManager = .default, loadImmediately: Bool = true) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate)
        }
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            return Date(timeIntervalSinceReferenceDate: try container.decode(Double.self))
        }
        if loadImmediately { load() }
    }

    static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("Straddle", isDirectory: true)
            .appendingPathComponent("sessions.json")
    }

    func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            sessions = []
            lastError = nil
            return
        }
        do {
            let data: Data
            do { data = try Data(contentsOf: fileURL) }
            catch { throw StoreError.read(error.localizedDescription) }
            do { sessions = try decoder.decode([PokerSession].self, from: data).sorted { $0.date > $1.date } }
            catch { throw StoreError.decode(error.localizedDescription) }
            lastError = nil
        } catch let error as StoreError {
            lastError = error
        } catch {
            lastError = .read(error.localizedDescription)
        }
    }

    @discardableResult
    func upsert(_ session: PokerSession) throws -> PokerSession {
        let previous = sessions
        var value = session
        value.updatedAt = .now
        if let index = sessions.firstIndex(where: { $0.id == value.id }) {
            sessions[index] = value
        } else {
            sessions.append(value)
        }
        sessions.sort { $0.date > $1.date }
        do {
            try persist()
            lastError = nil
            return value
        } catch {
            sessions = previous
            let storeError = error as? StoreError ?? .write(error.localizedDescription)
            lastError = storeError
            throw storeError
        }
    }

    func delete(id: UUID) throws {
        let previous = sessions
        sessions.removeAll { $0.id == id }
        do {
            try persist()
            lastError = nil
        } catch {
            sessions = previous
            let storeError = error as? StoreError ?? .write(error.localizedDescription)
            lastError = storeError
            throw storeError
        }
    }

    func delete(at offsets: IndexSet, from visibleSessions: [PokerSession]) throws {
        let ids = Set(offsets.compactMap { visibleSessions.indices.contains($0) ? visibleSessions[$0].id : nil })
        let previous = sessions
        sessions.removeAll { ids.contains($0.id) }
        do { try persist(); lastError = nil }
        catch {
            sessions = previous
            let storeError = error as? StoreError ?? .write(error.localizedDescription)
            lastError = storeError
            throw storeError
        }
    }

    func replaceAll(_ values: [PokerSession]) throws {
        let previous = sessions
        sessions = values.sorted { $0.date > $1.date }
        do { try persist(); lastError = nil }
        catch {
            sessions = previous
            let storeError = error as? StoreError ?? .write(error.localizedDescription)
            lastError = storeError
            throw storeError
        }
    }

    private func persist() throws {
        let directory = fileURL.deletingLastPathComponent()
        do { try fileManager.createDirectory(at: directory, withIntermediateDirectories: true) }
        catch { throw StoreError.createDirectory(error.localizedDescription) }
        let data: Data
        do { data = try encoder.encode(sessions) }
        catch { throw StoreError.encode(error.localizedDescription) }
        do { try data.write(to: fileURL, options: .atomic) }
        catch { throw StoreError.write(error.localizedDescription) }
    }
}
