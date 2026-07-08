import Foundation

/// Mirrors the web widget's session id scheme (`chatty_sid_{botId}_{hostKey}` in
/// localStorage) so the same visitor is recognized whether they arrive via web
/// or the native app, when `hostKey` is shared deliberately.
public enum ChattySession {
    public static func getOrCreateSessionId(botId: String, hostKey: String = "app") -> String {
        let key = "chatty_sid_\(botId)_\(hostKey)"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let sid = "v-\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        UserDefaults.standard.set(sid, forKey: key)
        return sid
    }
}
