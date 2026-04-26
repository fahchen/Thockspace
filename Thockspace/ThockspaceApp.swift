import SwiftUI
import AppKit

@main
struct ThockspaceApp: App {
    @StateObject private var appState = AppState()

    private static let menuBarIcon: NSImage = {
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "svg"),
           let image = NSImage(contentsOf: url) {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            return image
        }
        return NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Thockspace")!
    }()

    var body: some Scene {
        MenuBarExtra {
            SettingsView()
                .environmentObject(appState)
        } label: {
            Image(nsImage: Self.menuBarIcon)
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
