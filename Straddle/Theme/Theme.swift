import SwiftUI

enum StraddleTheme {
    static let background = Color(red: 0.025, green: 0.025, blue: 0.045)
    static let surface = Color(red: 0.075, green: 0.07, blue: 0.11)
    static let raised = Color(red: 0.11, green: 0.10, blue: 0.15)
    static let purple = Color(red: 0.62, green: 0.30, blue: 1.0)
    static let cyan = Color(red: 0.14, green: 0.87, blue: 0.96)
    static let positive = Color(red: 0.20, green: 0.90, blue: 0.68)
    static let negative = Color(red: 1.0, green: 0.35, blue: 0.48)
    static let secondaryText = Color.white.opacity(0.62)
    static let gradient = LinearGradient(colors: [purple, cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct StraddleCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(StraddleTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
    }
}

extension View {
    func straddleCard() -> some View { modifier(StraddleCard()) }
}

struct ProfitText: View {
    let value: Decimal
    var font: Font = .headline

    var body: some View {
        Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD").sign(strategy: .always()))
            .font(font.monospacedDigit())
            .foregroundStyle(value >= 0 ? StraddleTheme.positive : StraddleTheme.negative)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var tint: Color = StraddleTheme.cyan

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(StraddleTheme.secondaryText)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Capsule().fill(tint).frame(width: 28, height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .straddleCard()
    }
}

extension Decimal {
    var currencyText: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
    var signedCurrencyText: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").sign(strategy: .always()))
    }
}
