import SwiftUI
import AppKit

@main
struct ThockspaceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Thockspace", image: "MenuBarIconTemplate") {
            SettingsView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Window("Manage Packs", id: "manage-packs") {
            ManagePacksView()
                .environmentObject(appState)
                .containerBackground(.thinMaterial, for: .window)
                .onAppear { activateApp() }
        }
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        Window("Keystroke Stats", id: "stats") {
            StatsView()
                .environmentObject(appState)
                .containerBackground(.thinMaterial, for: .window)
                .onAppear { activateApp() }
        }
        .defaultSize(width: 760, height: 520)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }

    private func activateApp() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
