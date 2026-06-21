import Foundation

// MARK: - Categories

/// A top-level grouping shown in the sidebar (e.g. "Application Caches",
/// "Developer Junk"). Each category owns one or more `CleanupRule`s that know
/// how to discover removable items on disk.
struct CleanupCategory: Identifiable, Hashable, Sendable {
    let id: String
    /// Localization keys — resolved to text via `Localizer` at display time.
    let nameKey: LocKey
    let blurbKey: LocKey
    /// SF Symbol name used for the sidebar icon.
    let symbol: String
    let rules: [CleanupRule]
}

// MARK: - Removal mode

/// How an item should be removed. Trash is the default everywhere because it is
/// reversible — the user can always recover from the Trash.
enum RemovalMode: String, Codable, Sendable, CaseIterable {
    case trash      // Move to ~/.Trash (reversible)
    case delete     // Permanent removal (opt-in only)

    var label: String {
        switch self {
        case .trash:  return "Move to Trash"
        case .delete: return "Delete permanently"
        }
    }
}

// MARK: - Scan rules

/// Strategy describing *where* candidate items live and *how* they should be
/// enumerated. The scanner never invents paths — it only ever looks at paths
/// produced from these rules, and every result is re-validated by `SafetyGuard`
/// before it can be removed.
struct CleanupRule: Identifiable, Hashable, Sendable {
    enum Strategy: Hashable, Sendable {
        /// Treat each immediate child of `root` as its own removable item.
        /// Used for things like ~/Library/Caches where each subfolder is a
        /// separate app's cache and we want per-app granularity in the UI.
        case childrenOf(URL)

        /// Treat the entire contents of `root` as a single logical item with a
        /// fixed display name (e.g. "Xcode DerivedData"). The directory itself
        /// is preserved; only its contents are removed.
        case contentsAsOne(URL, name: String)
    }

    let id: String
    let strategy: Strategy
    /// Default removal mode for items produced by this rule.
    let defaultMode: RemovalMode
    /// Whether items from this rule are pre-selected after a scan. We leave
    /// anything remotely sensitive unchecked by default.
    let selectedByDefault: Bool

    var root: URL {
        switch strategy {
        case .childrenOf(let url):       return url
        case .contentsAsOne(let url, _): return url
        }
    }
}

// MARK: - Scan results

/// A concrete, on-disk thing the user can choose to remove. Produced by the
/// scanner, displayed in the UI, and (if selected) handed to the cleaner.
struct CleanupItem: Identifiable, Hashable, Sendable {
    let id: String                 // stable id = categoryID + url path
    let categoryID: String
    let ruleID: String
    let displayName: String
    /// For `.contentsAsOne` this is the container dir whose *contents* are
    /// removed; for `.childrenOf` this is the child path that is itself removed.
    let url: URL
    /// True when only the contents of `url` are removed (the dir stays).
    let clearsContentsOnly: Bool
    let size: Int64
    var mode: RemovalMode
    var isSelected: Bool
}

/// The full outcome of a scan, grouped for easy display.
struct ScanResult: Sendable {
    var itemsByCategory: [String: [CleanupItem]] = [:]

    var allItems: [CleanupItem] {
        itemsByCategory.values.flatMap { $0 }
    }

    func items(for categoryID: String) -> [CleanupItem] {
        (itemsByCategory[categoryID] ?? []).sorted { $0.size > $1.size }
    }

    func totalSize(for categoryID: String) -> Int64 {
        (itemsByCategory[categoryID] ?? []).reduce(0) { $0 + $1.size }
    }

    var grandTotal: Int64 {
        allItems.reduce(0) { $0 + $1.size }
    }
}

// MARK: - Formatting helpers

enum Format {
    /// Human-readable byte size, e.g. "1.2 GB".
    static func size(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        return f.string(fromByteCount: bytes)
    }
}
