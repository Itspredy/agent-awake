import SwiftUI

@main
struct AgentAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            StatusIcon()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)
    }
}
