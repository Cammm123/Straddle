import SwiftUI

@main
struct StraddleApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(StraddleTheme.purple)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: SessionStore
    @State private var showingNewSession = false

    var body: some View {
        TabView {
            NavigationStack { DashboardView(showingNewSession: $showingNewSession) }
                .tabItem { Label("Dashboard", systemImage: "sparkline") }
            NavigationStack { HistoryView(showingNewSession: $showingNewSession) }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            NavigationStack { AnalyticsView() }
                .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
        }
        .toolbarBackground(StraddleTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showingNewSession) {
            NavigationStack { SessionFormView() }
        }
        .alert("Storage Error", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK") { store.lastError = nil }
        } message: {
            Text(store.lastError?.localizedDescription ?? "Unknown error")
        }
    }
}
