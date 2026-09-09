import Foundation

enum SessionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case cash = "Cash Game"
    case tournament = "Tournament"

    var id: String { rawValue }
    var shortName: String { self == .cash ? "Cash" : "Tournament" }
}

struct PokerSession: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var date: Date
    var type: SessionType
    var game: String
    var stakes: String
    var venue: String
    var buyIn: Decimal
    var cashOut: Decimal
    var durationMinutes: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        type: SessionType = .cash,
        game: String = "No-Limit Hold’em",
        stakes: String = "",
        venue: String = "",
        buyIn: Decimal = 0,
        cashOut: Decimal = 0,
        durationMinutes: Int = 60,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.game = game
        self.stakes = stakes
        self.venue = venue
        self.buyIn = buyIn
        self.cashOut = cashOut
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var profit: Decimal { cashOut - buyIn }
    var durationHours: Double { Double(durationMinutes) / 60 }

    var isValid: Bool {
        buyIn >= 0 && cashOut >= 0 && durationMinutes > 0 &&
        !game.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
