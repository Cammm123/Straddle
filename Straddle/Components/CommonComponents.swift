import SwiftUI
import Charts

struct ProfitTrendChart: View {
    let points: [TrendPoint]
    var height: CGFloat = 190

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Profit", point.cumulativeProfit.doubleValue)
            )
            .foregroundStyle(LinearGradient(
                colors: [StraddleTheme.purple.opacity(0.35), StraddleTheme.cyan.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            ))
            LineMark(
                x: .value("Date", point.date),
                y: .value("Profit", point.cumulativeProfit.doubleValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(StraddleTheme.cyan)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(StraddleTheme.secondaryText)
                AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
                    }
                }
                .foregroundStyle(StraddleTheme.secondaryText)
                AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
            }
        }
        .frame(height: height)
        .accessibilityLabel("Cumulative profit trend")
    }
}

struct SessionRow: View {
    let session: PokerSession

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(session.type == .cash ? StraddleTheme.purple.opacity(0.18) : StraddleTheme.cyan.opacity(0.16))
                Image(systemName: session.type == .cash ? "suit.spade.fill" : "trophy.fill")
                    .foregroundStyle(session.type == .cash ? StraddleTheme.purple : StraddleTheme.cyan)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.game).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text("\(session.venue) • \(session.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(StraddleTheme.secondaryText).lineLimit(1)
                Text("\(session.stakes.isEmpty ? session.type.shortName : session.stakes) • \(durationText(session.durationMinutes))")
                    .font(.caption2).foregroundStyle(StraddleTheme.secondaryText)
            }
            Spacer()
            ProfitText(value: session.profit)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(StraddleTheme.gradient)
            Text(title).font(.headline).foregroundStyle(.white)
            Text(message).font(.subheadline).foregroundStyle(StraddleTheme.secondaryText).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
