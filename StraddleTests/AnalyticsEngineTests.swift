import XCTest
@testable import Straddle

final class AnalyticsEngineTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testCoreMetricsAndTrend() throws {
        let firstDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)))
        let secondDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 1, day: 2)))
        let thirdDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let sessions = [
            make(date: secondDate, type: .cash, game: "PLO", venue: "Bellagio", buyIn: 500, cashOut: 300, minutes: 120),
            make(date: firstDate, type: .cash, game: "NLH", venue: "Aria", buyIn: 200, cashOut: 500, minutes: 180),
            make(date: thirdDate, type: .tournament, game: "NLH", venue: "Aria", buyIn: 100, cashOut: 400, minutes: 300)
        ]

        let result = AnalyticsEngine.calculate(sessions)

        XCTAssertEqual(result.totalProfit, 400)
        XCTAssertEqual(result.totalHours, 10, accuracy: 0.0001)
        XCTAssertEqual(result.hourlyRate, 40)
        XCTAssertEqual(result.sessionCount, 3)
        XCTAssertEqual(result.wins, 2)
        XCTAssertEqual(result.winRate, 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(result.averageWin, 300)
        XCTAssertEqual(result.averageLoss, -200)
        XCTAssertEqual(result.bestSession?.profit, 300)
        XCTAssertEqual(result.worstSession?.profit, -200)
        XCTAssertEqual(result.cashProfit, 100)
        XCTAssertEqual(result.tournamentProfit, 300)
        XCTAssertEqual(result.tournamentROI, 3, accuracy: 0.0001)
        XCTAssertEqual(result.trend.map(\.cumulativeProfit), [300, 100, 400])
    }

    func testBreakdownsAggregateAndSortByProfit() {
        let sessions = [
            make(type: .cash, game: "NLH", venue: "Home", buyIn: 100, cashOut: 250, minutes: 60),
            make(type: .cash, game: "NLH", venue: "Home", buyIn: 100, cashOut: 50, minutes: 60),
            make(type: .cash, game: "PLO", venue: "Club", buyIn: 100, cashOut: 120, minutes: 30)
        ]
        let result = AnalyticsEngine.calculate(sessions)

        XCTAssertEqual(result.byVenue.map(\.name), ["Home", "Club"])
        XCTAssertEqual(result.byVenue.first?.profit, 100)
        XCTAssertEqual(result.byVenue.first?.sessions, 2)
        XCTAssertEqual(result.byVenue.first?.hourlyRate, 50)
        XCTAssertEqual(result.byGame.map(\.name), ["NLH", "PLO"])
    }

    func testEmptyAnalyticsAreSafe() {
        let result = AnalyticsEngine.calculate([])
        XCTAssertEqual(result.totalProfit, 0)
        XCTAssertEqual(result.hourlyRate, 0)
        XCTAssertEqual(result.winRate, 0)
        XCTAssertEqual(result.tournamentROI, 0)
        XCTAssertNil(result.bestSession)
        XCTAssertTrue(result.trend.isEmpty)
    }

    func testRangeFiltering() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 6, day: 30)))
        let recent = make(date: try XCTUnwrap(calendar.date(byAdding: .day, value: -5, to: now)))
        let old = make(date: try XCTUnwrap(calendar.date(byAdding: .day, value: -100, to: now)))
        XCTAssertEqual(AnalyticsEngine.sessions([recent, old], in: .month, now: now, calendar: calendar).map(\.id), [recent.id])
        XCTAssertEqual(AnalyticsEngine.sessions([recent, old], in: .all, now: now, calendar: calendar).count, 2)
    }

    private func make(
        date: Date = .now,
        type: SessionType = .cash,
        game: String = "NLH",
        venue: String = "Aria",
        buyIn: Decimal = 100,
        cashOut: Decimal = 200,
        minutes: Int = 60
    ) -> PokerSession {
        PokerSession(date: date, type: type, game: game, stakes: "1/2", venue: venue, buyIn: buyIn, cashOut: cashOut, durationMinutes: minutes)
    }
}
