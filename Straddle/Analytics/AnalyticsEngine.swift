import Foundation

struct TrendPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let cumulativeProfit: Decimal
}

struct Breakdown: Identifiable, Equatable {
    let name: String
    let sessions: Int
    let hours: Double
    let profit: Decimal

    var id: String { name }
    var hourlyRate: Decimal {
        guard hours > 0 else { return 0 }
        return profit / Decimal(hours)
    }
}

struct SessionAnalytics: Equatable {
    let totalProfit: Decimal
    let totalHours: Double
    let sessionCount: Int
    let wins: Int
    let averageWin: Decimal
    let averageLoss: Decimal
    let bestSession: PokerSession?
    let worstSession: PokerSession?
    let cashProfit: Decimal
    let tournamentProfit: Decimal
    let tournamentBuyIns: Decimal
    let trend: [TrendPoint]
    let byVenue: [Breakdown]
    let byGame: [Breakdown]

    var hourlyRate: Decimal {
        guard totalHours > 0 else { return 0 }
        return totalProfit / Decimal(totalHours)
    }
    var winRate: Double { sessionCount == 0 ? 0 : Double(wins) / Double(sessionCount) }
    var tournamentROI: Double {
        guard tournamentBuyIns > 0 else { return 0 }
        return (tournamentProfit / tournamentBuyIns).doubleValue
    }
    var losses: Int { sessionCount - wins }
}

enum AnalyticsEngine {
    static func calculate(_ sessions: [PokerSession]) -> SessionAnalytics {
        let totalProfit = sessions.reduce(Decimal.zero) { $0 + $1.profit }
        let totalHours = sessions.reduce(0.0) { $0 + $1.durationHours }
        let winning = sessions.filter { $0.profit > 0 }
        let losing = sessions.filter { $0.profit < 0 }
        let averageWin = winning.isEmpty ? 0 : winning.reduce(Decimal.zero) { $0 + $1.profit } / Decimal(winning.count)
        let averageLoss = losing.isEmpty ? 0 : losing.reduce(Decimal.zero) { $0 + $1.profit } / Decimal(losing.count)
        let cash = sessions.filter { $0.type == .cash }
        let tournaments = sessions.filter { $0.type == .tournament }
        let sorted = sessions.sorted {
            if $0.date == $1.date { return $0.createdAt < $1.createdAt }
            return $0.date < $1.date
        }
        var running = Decimal.zero
        let trend = sorted.map { session -> TrendPoint in
            running += session.profit
            return TrendPoint(id: session.id, date: session.date, cumulativeProfit: running)
        }

        return SessionAnalytics(
            totalProfit: totalProfit,
            totalHours: totalHours,
            sessionCount: sessions.count,
            wins: winning.count,
            averageWin: averageWin,
            averageLoss: averageLoss,
            bestSession: sessions.max { $0.profit < $1.profit },
            worstSession: sessions.min { $0.profit < $1.profit },
            cashProfit: cash.reduce(Decimal.zero) { $0 + $1.profit },
            tournamentProfit: tournaments.reduce(Decimal.zero) { $0 + $1.profit },
            tournamentBuyIns: tournaments.reduce(Decimal.zero) { $0 + $1.buyIn },
            trend: trend,
            byVenue: breakdown(sessions, key: { $0.venue }),
            byGame: breakdown(sessions, key: { $0.game })
        )
    }

    static func sessions(_ sessions: [PokerSession], in range: AnalyticsRange, now: Date = .now, calendar: Calendar = .current) -> [PokerSession] {
        guard let start = range.startDate(now: now, calendar: calendar) else { return sessions }
        return sessions.filter { $0.date >= start && $0.date <= now }
    }

    private static func breakdown(_ sessions: [PokerSession], key: (PokerSession) -> String) -> [Breakdown] {
        Dictionary(grouping: sessions, by: key).map { name, values in
            Breakdown(
                name: name.isEmpty ? "Unspecified" : name,
                sessions: values.count,
                hours: values.reduce(0) { $0 + $1.durationHours },
                profit: values.reduce(Decimal.zero) { $0 + $1.profit }
            )
        }.sorted { lhs, rhs in
            if lhs.profit == rhs.profit { return lhs.name < rhs.name }
            return lhs.profit > rhs.profit
        }
    }
}

enum AnalyticsRange: String, CaseIterable, Identifiable {
    case month = "30D"
    case quarter = "90D"
    case year = "1Y"
    case all = "All"
    var id: String { rawValue }

    func startDate(now: Date, calendar: Calendar) -> Date? {
        switch self {
        case .month: calendar.date(byAdding: .day, value: -30, to: now)
        case .quarter: calendar.date(byAdding: .day, value: -90, to: now)
        case .year: calendar.date(byAdding: .year, value: -1, to: now)
        case .all: nil
        }
    }
}
