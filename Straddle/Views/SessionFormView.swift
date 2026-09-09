import SwiftUI

struct SessionFormView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    private let original: PokerSession?
    @State private var date: Date
    @State private var type: SessionType
    @State private var game: String
    @State private var stakes: String
    @State private var venue: String
    @State private var buyIn: Decimal?
    @State private var cashOut: Decimal?
    @State private var hours: Int
    @State private var minutes: Int
    @State private var notes: String
    @State private var saveError: String?

    init(session: PokerSession? = nil) {
        original = session
        _date = State(initialValue: session?.date ?? .now)
        _type = State(initialValue: session?.type ?? .cash)
        _game = State(initialValue: session?.game ?? "No-Limit Hold’em")
        _stakes = State(initialValue: session?.stakes ?? "")
        _venue = State(initialValue: session?.venue ?? "")
        _buyIn = State(initialValue: session?.buyIn)
        _cashOut = State(initialValue: session?.cashOut)
        _hours = State(initialValue: (session?.durationMinutes ?? 60) / 60)
        _minutes = State(initialValue: (session?.durationMinutes ?? 60) % 60)
        _notes = State(initialValue: session?.notes ?? "")
    }

    private var draft: PokerSession {
        PokerSession(
            id: original?.id ?? UUID(),
            date: date,
            type: type,
            game: game.trimmingCharacters(in: .whitespacesAndNewlines),
            stakes: stakes.trimmingCharacters(in: .whitespacesAndNewlines),
            venue: venue.trimmingCharacters(in: .whitespacesAndNewlines),
            buyIn: buyIn ?? 0,
            cashOut: cashOut ?? 0,
            durationMinutes: hours * 60 + minutes,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: original?.createdAt ?? .now,
            updatedAt: .now
        )
    }

    var body: some View {
        Form {
            Section("Format") {
                Picker("Session type", selection: $type) {
                    ForEach(SessionType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                DatePicker("Date", selection: $date, in: ...Date.now)
            }

            Section("Game") {
                TextField("Game (e.g. No-Limit Hold’em)", text: $game)
                    .textInputAutocapitalization(.words)
                TextField(type == .cash ? "Stakes (e.g. $2/$5)" : "Tournament / level", text: $stakes)
                TextField("Venue", text: $venue).textInputAutocapitalization(.words)
            }

            Section("Results") {
                HStack {
                    Text("Buy-in")
                    Spacer()
                    TextField("0", value: $buyIn, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Cash-out")
                    Spacer()
                    TextField("0", value: $cashOut, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Profit")
                    Spacer()
                    ProfitText(value: (cashOut ?? 0) - (buyIn ?? 0))
                }
            }

            Section("Duration") {
                Stepper("Hours: \(hours)", value: $hours, in: 0...48)
                Picker("Minutes", selection: $minutes) {
                    ForEach([0, 5, 10, 15, 20, 30, 45], id: \.self) { Text("\($0) min").tag($0) }
                }
            }

            Section("Notes (optional)") {
                TextField("Table, lineup, key hands…", text: $notes, axis: .vertical).lineLimit(3...7)
            }
        }
        .scrollContentBackground(.hidden)
        .background(StraddleTheme.background)
        .navigationTitle(original == nil ? "New Session" : "Edit Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).fontWeight(.semibold).disabled(!draft.isValid)
            }
        }
        .alert("Couldn’t Save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "Unknown error") }
    }

    private func save() {
        do {
            try store.upsert(draft)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
