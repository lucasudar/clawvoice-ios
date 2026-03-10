import AppIntents
import Foundation

/// Siri Shortcut — "Hey Siri, [your custom phrase]" activates the assistant.
///
/// Setup:
///   Shortcuts app → New shortcut → Add Action → search "ClawVoice" → Activate Assistant
///   Tap "Add to Siri" → record your phrase (e.g. "Mr Krabs", "Hey Assistant")
struct ActivateAssistantIntent: AppIntent {

    static var title: LocalizedStringResource = "Activate Assistant"
    static var description = IntentDescription(
        "Wake up your OpenClaw voice assistant and start listening.",
        categoryName: "ClawVoice"
    )
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Small delay to let the app finish launching before we post the notification
        try await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            NotificationCenter.default.post(name: .clawVoiceActivate, object: nil)
        }
        return .result()
    }
}

extension Notification.Name {
    static let clawVoiceActivate = Notification.Name("clawVoiceActivate")
}
