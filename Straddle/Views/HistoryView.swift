import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: SessionStore
    @Binding var showingNewSession: Bool
    @State private var query = ""
    @State private var filter: SessionFilter = .all

    private var visibleSessions: [PokerSession] {
        store.sessions.filter { session in
            let matchesType = filter == .all || (filter == .cash && session.type == .cash) || (filter == .tournaments && session.type == .tournament)
            let text = "\(session.game) \(session.stakes) \(session.venue) \(session.notes)"
            return matchesType && (query.isEmpty || text.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ZStack {
            StraddleTheme.background.ignoresSafeArea()
            if store.sessions.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath", title: "No sessions", message: "Log a cash game or tournament. You can edit every detail later.", actionTitle: "Add session") { showingNewSession = true }
                    .padding()
            } else {
                List {
                    Picker("Filter", selection: $filter) {
                        ForEach(SessionFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))

                    if visibleSessions.isEmpty {
                        EmptyStateView(icon: "magnifyingglass", title: "No matches", message: "Try a different search or filter.")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(visibleSessions) { session in
                            NavigationLink(value: session.id) { SessionRow(session: session) }
                                .listRowBackground(StraddleTheme.surface)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { try? store.delete(id: session.id) } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                        .onDelete { offsets in try? store.delete(at: offsets, from: visibleSessions) }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .searchable(text: $query, prompt: "Game, venue, notes")
        .navigationDestination(for: UUID.self) { id in
            if let session = store.sessions.first(where: { $0.id == id }) {
                SessionDetailView(sessionID: session.id)
            } else {
                ContentUnavailableView("Session unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewSession = true } label: { Image(systemName: "plus").fontWeight(.bold) }
            }
        }
    }
}

private enum SessionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case cash = "Cash"
    case tournaments = "Tournaments"
    var id: String { rawValue }
}

struct SessionDetailView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID
    @State private var editing = false
    @State private var confirmDelete = false

    private var session: PokerSession? { store.sessions.first { $0.id == sessionID } }

    var body: some View {
        ZStack {
            StraddleTheme.background.ignoresSafeArea()
            if let session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.type.rawValue.uppercased()).font(.caption.weight(.bold)).tracking(1).foregroundStyle(StraddleTheme.cyan)
                            Text(session.game).font(.largeTitle.bold()).foregroundStyle(.white)
                            Text("\(session.stakes.isEmpty ? "No stakes entered" : session.stakes) • \(session.venue)").foregroundStyle(StraddleTheme.secondaryText)
                            ProfitText(value: session.profit, font: .system(size: 36, weight: .bold, design: .rounded))
                        }.frame(maxWidth: .infinity, alignment: .leading).straddleCard()

                        detailCard(session)
                        if !session.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes").font(.headline)
                                Text(session.notes).foregroundStyle(StraddleTheme.secondaryText)
                            }.frame(maxWidth: .infinity, alignment: .leading).straddleCard()
                        }
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete Session", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }.padding()
                }
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Edit") { editing = true }.disabled(session == nil) }
        .sheet(isPresented: $editing) {
            if let session { NavigationStack { SessionFormView(session: session) } }
        }
        .confirmationDialog("Delete this session?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                do { try store.delete(id: sessionID); dismiss() } catch { }
            }
        }
    }

    private func detailCard(_ session: PokerSession) -> some View {
        VStack(spacing: 13) {
            detailLine("Date", session.date.formatted(date: .long, time: .omitted))
            Divider().overlay(Color.white.opacity(0.08))
            detailLine("Buy-in", session.buyIn.currencyText)
            detailLine("Cash-out", session.cashOut.currencyText)
            detailLine("Duration", String(format: "%.1f hours", session.durationHours))
            detailLine("Hourly", session.durationHours > 0 ? (session.profit / Decimal(session.durationHours)).signedCurrencyText : "—")
        }.straddleCard()
    }

    private func detailLine(_ label: String, _ value: String) -> some View {
        HStack { Text(label).foregroundStyle(StraddleTheme.secondaryText); Spacer(); Text(value).fontWeight(.medium) }
    }
}
