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
    }
}
