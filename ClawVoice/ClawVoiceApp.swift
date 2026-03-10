import SwiftUI

@main
struct ClawVoiceApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var session = AssistantSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
