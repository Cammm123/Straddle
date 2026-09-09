import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: SessionStore
    @Binding var showingNewSession: Bool

    private var analytics: SessionAnalytics { AnalyticsEngine.calculate(store.sessions) }

    var body: some View {
        ZStack {
            StraddleTheme.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    hero
                    trend
                    quickStats
                    recent
                }
                .padding()
            }
        }
        .navigationTitle("Straddle")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewSession = true } label: {
                    Image(systemName: "plus").fontWeight(.bold)
                }
                .accessibilityLabel("Add session")
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("ALL-TIME PROFIT").font(.caption.weight(.semibold)).tracking(1.3).foregroundStyle(StraddleTheme.secondaryText)
            ProfitText(value: analytics.totalProfit, font: .system(size: 42, weight: .bold, design: .rounded))
            HStack(spacing: 16) {
                Label("\(analytics.sessionCount) sessions", systemImage: "rectangle.stack")
                Label(String(format: "%.1f hours", analytics.totalHours), systemImage: "clock")
            }
            .font(.caption).foregroundStyle(StraddleTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(StraddleTheme.surface)
                .overlay(alignment: .topTrailing) {
                    Circle().fill(StraddleTheme.purple.opacity(0.16)).frame(width: 150).blur(radius: 35).offset(x: 38, y: -55)
                }
        }
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(StraddleTheme.purple.opacity(0.2)) }
    }

    private var trend: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profit trend").font(.headline).foregroundStyle(.white)
            if analytics.trend.isEmpty {
                EmptyStateView(icon: "chart.xyaxis.line", title: "No trend yet", message: "Log your first session to start tracking.", actionTitle: "Add session") { showingNewSession = true }
            } else {
                ProfitTrendChart(points: analytics.trend)
            }
        }
        .straddleCard()
    }

    private var quickStats: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(title: "Hourly rate", value: analytics.hourlyRate.signedCurrencyText, tint: StraddleTheme.cyan)
            MetricCard(title: "Win rate", value: analytics.winRate.formatted(.percent.precision(.fractionLength(0))), tint: StraddleTheme.purple)
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent sessions").font(.headline).foregroundStyle(.white)
                Spacer()
            }
            if store.sessions.isEmpty {
                Text("Your latest sessions will appear here.").font(.subheadline).foregroundStyle(StraddleTheme.secondaryText).padding(.vertical, 10)
            } else {
                ForEach(store.sessions.prefix(4)) { session in
                    SessionRow(session: session)
                    if session.id != store.sessions.prefix(4).last?.id { Divider().overlay(Color.white.opacity(0.08)) }
                }
            }
        }
        .straddleCard()
    }
}
