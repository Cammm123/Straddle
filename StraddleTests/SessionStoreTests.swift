import XCTest
@testable import Straddle

@MainActor
final class SessionStoreTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StraddleTests-\(UUID().uuidString)", isDirectory: true)
        fileURL = directory.appendingPathComponent("sessions.json")
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testUpsertPersistsAndReloadsSession() throws {
        let store = SessionStore(fileURL: fileURL, loadImmediately: false)
        let session = PokerSession(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            type: .cash,
            game: "No-Limit Hold’em",
            stakes: "$2/$5",
            venue: "Aria",
            buyIn: 500,
            cashOut: 825,
            durationMinutes: 210
        )

        let saved = try store.upsert(session)
        XCTAssertEqual(store.sessions, [saved])

        let reloaded = SessionStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.sessions, [saved])
        XCTAssertNil(reloaded.lastError)
    }

    func testUpdateDoesNotDuplicateSession() throws {
        let store = SessionStore(fileURL: fileURL, loadImmediately: false)
        var session = PokerSession(venue: "Home", buyIn: 100, cashOut: 150)
        session = try store.upsert(session)
        session.cashOut = 250
        let updated = try store.upsert(session)

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions.first?.profit, 150)
        XCTAssertEqual(store.sessions.first?.id, updated.id)
    }

    func testDeletePersistsRemoval() throws {
        let store = SessionStore(fileURL: fileURL, loadImmediately: false)
        let session = try store.upsert(PokerSession(venue: "Bellagio", buyIn: 200, cashOut: 0))
        try store.delete(id: session.id)

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertTrue(SessionStore(fileURL: fileURL).sessions.isEmpty)
    }
}
