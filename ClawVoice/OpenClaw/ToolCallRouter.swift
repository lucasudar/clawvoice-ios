import Foundation

/// Routes Gemini tool calls to OpenClaw and returns tool responses.
final class ToolCallRouter {

    private let bridge = OpenClawBridge.shared

    /// Handle a Gemini function call. Returns the text result.
    func handle(id: String, name: String, args: [String: String]) async -> String {
        guard name == "execute" else {
            return "Unknown tool: \(name)"
        }
        let task = args["task"] ?? args.values.first ?? "?"
        do {
            let result = try await bridge.execute(task: task)
            return result
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
