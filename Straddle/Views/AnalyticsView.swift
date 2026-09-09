import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var store: SessionStore
    @State private var range: AnalyticsRange = .all

    private var filtered: [PokerSession] { AnalyticsEngine.sessions(store.sessions, in: range) }
    private var analytics: SessionAnalytics { AnalyticsEngine.calculate(filtered) }

    var body: some View {
        ZStack {
            StraddleTheme.background.ignoresSafeArea()
            if store.sessions.isEmpty {
                EmptyStateView(icon: "chart.xyaxis.line", title: "Analytics await", message: "Your performance insights will build as you log sessions.").padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Picker("Range", selection: $range) {
                            ForEach(AnalyticsRange.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)

                        if filtered.isEmpty {
                            EmptyStateView(icon: "calendar.badge.exclamationmark", title: "No sessions in this range", message: "Choose a longer timeframe.").straddleCard()
                        } else {
                            overview
                            profitChart
                            averages
                            formatBreakdown
                            sessionExtremes
                            BreakdownSection(title: "By venue", values: analytics.byVenue)
                            BreakdownSection(title: "By game", values: analytics.byGame)
                        }
                    }.padding()
                }
            }
        }
        .navigationTitle("Analytics")
    }

    private var overview: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(title: "Net profit", value: analytics.totalProfit.signedCurrencyText, tint: analytics.totalProfit >= 0 ? StraddleTheme.positive : StraddleTheme.negative)
            MetricCard(title: "Hourly rate", value: analytics.hourlyRate.signedCurrencyText)
            MetricCard(title: "Total hours", value: String(format: "%.1f", analytics.totalHours), tint: StraddleTheme.purple)
            MetricCard(title: "Sessions", value: "\(analytics.sessionCount)", tint: StraddleTheme.purple)
            MetricCard(title: "Win rate", value: analytics.winRate.formatted(.percent.precision(.fractionLength(0))))
            MetricCard(title: "Tournament ROI", value: analytics.tournamentROI.formatted(.percent.precision(.fractionLength(1))), tint: StraddleTheme.purple)
        }
    }

    private var profitChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cumulative profit").font(.headline)
            ProfitTrendChart(points: analytics.trend, height: 220)
        }.straddleCard()
    }

    private var averages: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Winning profile").font(.headline)
            statLine("Average win", analytics.averageWin.signedCurrencyText, color: StraddleTheme.positive)
            statLine("Average loss", analytics.averageLoss.signedCurrencyText, color: StraddleTheme.negative)
            statLine("Winning sessions", "\(analytics.wins) of \(analytics.sessionCount)")
        }.straddleCard()
    }

    private var formatBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cash vs tournament").font(.headline)
            Chart {
                BarMark(x: .value("Profit", analytics.cashProfit.doubleValue), y: .value("Format", "Cash"))
                    .foregroundStyle(StraddleTheme.purple)
                BarMark(x: .value("Profit", analytics.tournamentProfit.doubleValue), y: .value("Format", "Tournament"))
                    .foregroundStyle(StraddleTheme.cyan)
            }
            .chartXAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(Color.white.opacity(0.08)); AxisValueLabel().foregroundStyle(StraddleTheme.secondaryText) } }
            .frame(height: 110)
            statLine("Cash profit", analytics.cashProfit.signedCurrencyText)
            statLine("Tournament profit", analytics.tournamentProfit.signedCurrencyText)
            statLine("Tournament buy-ins", analytics.tournamentBuyIns.currencyText)
            statLine("Tournament ROI", analytics.tournamentROI.formatted(.percent.precision(.fractionLength(1))))
        }.straddleCard()
    }

    @ViewBuilder private var sessionExtremes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highs & lows").font(.headline)
            if let best = analytics.bestSession {
                extremeRow("Best", session: best, color: StraddleTheme.positive)
            }
            if let worst = analytics.worstSession {
                extremeRow("Worst", session: worst, color: StraddleTheme.negative)
            }
        }.straddleCard()
    }

    private func extremeRow(_ label: String, session: PokerSession, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(StraddleTheme.secondaryText)
                Text(session.game + " • " + session.venue).font(.subheadline.weight(.medium)).lineLimit(1)
            }
            Spacer()
            Text(session.profit.signedCurrencyText).font(.headline.monospacedDigit()).foregroundStyle(color)
        }
    }

    private func statLine(_ label: String, _ value: String, color: Color = .white) -> some View {
        HStack { Text(label).foregroundStyle(StraddleTheme.secondaryText); Spacer(); Text(value).fontWeight(.semibold).monospacedDigit().foregroundStyle(color) }
    }
}

private struct BreakdownSection: View {
    let title: String
    let values: [Breakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ForEach(values) { value in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(value.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                        Text("\(value.sessions) sessions • \(value.hours.formatted(.number.precision(.fractionLength(1))))h • \(value.hourlyRate.signedCurrencyText)/hr")
                            .font(.caption).foregroundStyle(StraddleTheme.secondaryText)
                    }
                    Spacer()
                    ProfitText(value: value.profit)
                }
                if value.id != values.last?.id { Divider().overlay(Color.white.opacity(0.08)) }
            }
        }.straddleCard()
    }
}
