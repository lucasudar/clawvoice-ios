import Foundation

/// Debug logger — DISABLED (use Xcode console instead)
/// TODO: remove this file before production release
enum DebugLog {
    static func setup() {}
    static func connection(_ event: String, sessionId: String? = nil, sessionAge: TimeInterval? = nil) {}
    static func error(_ message: String) {}
}
