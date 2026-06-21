import Foundation

/// The curated, hand-audited list of what Sweep is allowed to clean. Adding a
/// new cleanup target means adding a rule here — and every path produced is
/// still re-checked by `SafetyGuard` at scan and removal time.
enum CleanupCatalog {

    private static let home = FileManager.default.homeDirectoryForCurrentUser
    private static var lib: URL { home.appendingPathComponent("Library", isDirectory: true) }

    private static func L(_ rel: String) -> URL {
        lib.appendingPathComponent(rel, isDirectory: true)
    }
    private static func H(_ rel: String) -> URL {
        home.appendingPathComponent(rel, isDirectory: true)
    }

    static let categories: [CleanupCategory] = [

        CleanupCategory(
            id: "app-caches",
            nameKey: .catCachesName,
            blurbKey: .catCachesBlurb,
            symbol: "shippingbox",
            rules: [
                CleanupRule(
                    id: "user-caches",
                    strategy: .childrenOf(L("Caches")),
                    defaultMode: .trash,
                    selectedByDefault: true
                )
            ]
        ),

        CleanupCategory(
            id: "logs",
            nameKey: .catLogsName,
            blurbKey: .catLogsBlurb,
            symbol: "doc.text.magnifyingglass",
            rules: [
                CleanupRule(
                    id: "user-logs",
                    strategy: .childrenOf(L("Logs")),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "crash-reports",
                    strategy: .childrenOf(L("Application Support/CrashReporter")),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
            ]
        ),

        CleanupCategory(
            id: "trash",
            nameKey: .catTrashName,
            blurbKey: .catTrashBlurb,
            symbol: "trash",
            rules: [
                CleanupRule(
                    id: "trash-contents",
                    strategy: .childrenOf(H(".Trash")),
                    // Already in the Trash — only permanent delete frees space.
                    defaultMode: .delete,
                    selectedByDefault: false
                )
            ]
        ),

        CleanupCategory(
            id: "developer",
            nameKey: .catDevName,
            blurbKey: .catDevBlurb,
            symbol: "hammer",
            rules: [
                CleanupRule(
                    id: "xcode-derived-data",
                    strategy: .contentsAsOne(L("Developer/Xcode/DerivedData"), name: "Xcode DerivedData"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "xcode-ios-device-support",
                    strategy: .childrenOf(L("Developer/Xcode/iOS DeviceSupport")),
                    defaultMode: .trash,
                    selectedByDefault: false
                ),
                CleanupRule(
                    id: "coresimulator-caches",
                    strategy: .contentsAsOne(L("Developer/CoreSimulator/Caches"), name: "CoreSimulator Caches"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "swiftpm-cache",
                    strategy: .contentsAsOne(L("Caches/org.swift.swiftpm"), name: "SwiftPM Cache"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "npm-cache",
                    strategy: .contentsAsOne(H(".npm/_cacache"), name: "npm Cache"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "gradle-cache",
                    strategy: .contentsAsOne(H(".gradle/caches"), name: "Gradle Cache"),
                    defaultMode: .trash,
                    selectedByDefault: false
                ),
                CleanupRule(
                    id: "homebrew-cache",
                    strategy: .contentsAsOne(L("Caches/Homebrew"), name: "Homebrew Cache"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "cocoapods-cache",
                    strategy: .contentsAsOne(L("Caches/CocoaPods"), name: "CocoaPods Cache"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
                CleanupRule(
                    id: "pip-cache",
                    strategy: .contentsAsOne(L("Caches/pip"), name: "pip Cache"),
                    defaultMode: .trash,
                    selectedByDefault: true
                ),
            ]
        ),
    ]

    static func category(id: String) -> CleanupCategory? {
        categories.first { $0.id == id }
    }
}
