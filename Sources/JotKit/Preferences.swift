import Foundation

public enum Preferences {
    private static let saveDirectoryKey = "saveDirectory"
    private static let defaultTagKey = "defaultTag"
    private static let shortcutKeyKey = "shortcutKey"
    private static let shortcutModifiersKey = "shortcutModifiers"

    public static var saveDirectory: String {
        get {
            UserDefaults.standard.string(forKey: saveDirectoryKey)
                ?? NSHomeDirectory() + "/Documents"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: saveDirectoryKey)
        }
    }

    public static var defaultTag: String {
        get {
            UserDefaults.standard.string(forKey: defaultTagKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultTagKey)
        }
    }

    /// The key character for the global shortcut (e.g. "N"). Shift-aware via `charactersIgnoringModifiers`.
    public static var shortcutKey: String {
        get {
            UserDefaults.standard.string(forKey: shortcutKeyKey) ?? "N"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: shortcutKeyKey)
        }
    }

    /// Modifier flags raw value for the global shortcut. Default: Command | Shift (1 << 20 | 1 << 17).
    public static var shortcutModifiers: UInt {
        get {
            guard UserDefaults.standard.object(forKey: shortcutModifiersKey) != nil else {
                return (1 << 20) | (1 << 17)
            }
            return UInt(UserDefaults.standard.integer(forKey: shortcutModifiersKey))
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: shortcutModifiersKey)
        }
    }
}
