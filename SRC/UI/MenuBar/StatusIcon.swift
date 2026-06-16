import SwiftUI

struct StatusIcon: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isActive {
            Image(systemName: "sun.max.fill")
        } else {
            Image(systemName: "moon.fill")
        }
    }
}
