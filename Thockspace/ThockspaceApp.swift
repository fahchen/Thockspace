import SwiftUI

@main
struct ThockspaceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Thockspace", systemImage: "keyboard") {
            SettingsView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Window("Manage Packs", id: "manage-packs") {
            ManagePacksView()
                .environmentObject(appState)
        }
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)

        Window("Keystroke Stats", id: "stats") {
            StatsView()
                .environmentObject(appState)
        }
        .defaultSize(width: 760, height: 520)
        .windowResizability(.contentSize)
    }
}
