import Foundation
import Combine

/// Central coordinator: owns Gemini + Audio + ToolCallRouter.
@MainActor
final class AssistantSession: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case connecting
        case listening
        case thinking
        case speaking
        case error(String)

        var label: String {
            switch self {
            case .idle:        return "Tap to talk"
            case .connecting:  return "Connecting…"
            case .listening:   return "Listening…"
            case .thinking:    return "Thinking…"
            case .speaking:    return "Speaking…"
            case .error(let e): return e
            }
        }

        var isActive: Bool {
            switch self {
            case .idle, .error: return false
            default:            return true
            }
        }
    }

    // MARK: - Published

    @Published var state: State = .idle
    @Published var transcript: String = ""

    // MARK: - Private

    private let gemini = GeminiLiveService()
    private let audio  = AudioManager()
    private let router = ToolCallRouter()
    private var siriObserver: NSObjectProtocol?

    // MARK: - Init

    init() {
        gemini.delegate = self
        observeSiriShortcut()
    }

    // MARK: - Public API

    func toggle() {
        if state.isActive {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard state == .idle || {
            if case .error = state { return true } else { return false }
        }() else { return }

        transcript = ""
        state = .connecting
        gemini.connect()
    }

    func stop() {
        gemini.disconnect()
        audio.stopCapture()
        state = .idle
    }

    // MARK: - Private

    private func observeSiriShortcut() {
        siriObserver = NotificationCenter.default.addObserver(
            forName: .clawVoiceActivate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.start() }
        }
    }
}

// MARK: - GeminiLiveServiceDelegate

extension AssistantSession: GeminiLiveServiceDelegate {

    nonisolated func geminiDidConnect() {
        Task { @MainActor in
            self.state = .listening
            do {
                try self.audio.startCapture { [weak self] chunk in
                    self?.gemini.sendAudio(chunk)
                }
            } catch {
                self.state = .error("Microphone error: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func geminiDidReceiveAudio(_ data: Data) {
        Task { @MainActor in
            self.state = .speaking
            self.audio.playAudio(data)
        }
    }

    nonisolated func geminiDidReceiveText(_ text: String) {
        Task { @MainActor in
            self.transcript += text
        }
    }

    nonisolated func geminiDidReceiveToolCall(id: String, name: String, args: [String: String]) {
        Task { @MainActor in
            self.state = .thinking
            let result = await self.router.handle(id: id, name: name, args: args)
            self.gemini.sendToolResponse(id: id, output: result)
            self.state = .listening
        }
    }

    nonisolated func geminiDidDisconnect(error: Error?) {
        Task { @MainActor in
            self.audio.stopCapture()
            if let error {
                self.state = .error(error.localizedDescription)
            } else {
                self.state = .idle
            }
        }
    }
}
