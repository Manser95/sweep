import Foundation

/// The single chokepoint that decides whether a path is allowed to be touched.
///
/// Design philosophy: **allowlist first, denylist second.** A path must live
/// under one of a small set of explicitly-approved roots, must not match any
/// protected location, and (after symlink resolution) must still stay inside an
/// approved root. If any check is ambiguous, the answer is "no".
///
/// Every removal in the app — without exception — goes through `validate`.
enum SafetyGuard {

    enum Rejection: Error, CustomStringConvertible {
        case outsideAllowedRoots
        case protectedLocation
        case escapesViaSymlink
        case isAllowedRootItself
        case systemPath
        case homeRootItself
        case tooShallow

        var description: String {
            switch self {
            case .outsideAllowedRoots: return "Path is outside the approved cleanup roots."
            case .protectedLocation:   return "Path is a protected user location."
            case .escapesViaSymlink:   return "Resolved path escapes the approved roots (symlink)."
            case .isAllowedRootItself: return "Refusing to remove an approved root directory itself."
            case .systemPath:          return "Path is a protected system location."
            case .homeRootItself:      return "Refusing to operate on the home directory itself."
            case .tooShallow:          return "Path is suspiciously shallow."
            }
        }
    }

    static let home = FileManager.default.homeDirectoryForCurrentUser

    /// Directories whose *contents* (or immediate children) are eligible for
    /// cleanup. Nothing outside these is ever removable.
    static var allowedRoots: [URL] {
        let lib = home.appendingPathComponent("Library", isDirectory: true)
        return [
            lib.appendingPathComponent("Caches", isDirectory: true),
            lib.appendingPathComponent("Logs", isDirectory: true),
            lib.appendingPathComponent("Developer", isDirectory: true),
            lib.appendingPathComponent("Application Support/CrashReporter", isDirectory: true),
            home.appendingPathComponent(".Trash", isDirectory: true),
            home.appendingPathComponent(".npm", isDirectory: true),
            home.appendingPathComponent(".gradle/caches", isDirectory: true),
            home.appendingPathComponent(".cache", isDirectory: true),
        ].map { $0.standardizedFileURL }
    }

    /// Locations that must never be touched even if they happen to fall under an
    /// allowed root. This is defense-in-depth, not the primary mechanism.
    static var protectedLocations: [URL] {
        let lib = home.appendingPathComponent("Library", isDirectory: true)
        return [
            home.appendingPathComponent("Documents", isDirectory: true),
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Downloads", isDirectory: true),
            home.appendingPathComponent("Pictures", isDirectory: true),
            home.appendingPathComponent("Movies", isDirectory: true),
            home.appendingPathComponent("Music", isDirectory: true),
            lib.appendingPathComponent("Keychains", isDirectory: true),
            lib.appendingPathComponent("Mobile Documents", isDirectory: true), // iCloud Drive
            lib.appendingPathComponent("Messages", isDirectory: true),
            lib.appendingPathComponent("Mail", isDirectory: true),
            lib.appendingPathComponent("Developer/Xcode/Archives", isDirectory: true), // shipping builds!
        ].map { $0.standardizedFileURL }
    }

    /// Absolute prefixes that are always off-limits (system + other users).
    static let systemPrefixes = [
        "/System", "/Library", "/usr", "/bin", "/sbin", "/private/var",
        "/opt", "/Applications", "/cores", "/Network", "/Volumes",
    ]

    /// Validate a path for removal. Throws `Rejection` if the path is not safe.
    /// - Parameter contentsOnly: when true the *directory itself* is preserved
    ///   and only its contents will be removed; we still validate the dir path.
    static func validate(_ url: URL, contentsOnly: Bool) throws {
        let target = url.standardizedFileURL
        // All matching is done on the normalized string path. `URL.path` strips
        // any trailing slash, so comparisons are immune to the directory/file
        // (trailing-slash) ambiguity that `URL ==` is sensitive to — that bug
        // could otherwise let a protected dir slip through on machines where the
        // directory doesn't exist (`appendingPathComponent` decides the trailing
        // slash from the filesystem).
        let path = target.path

        // 1. Never operate on the home dir or anything dangerously shallow.
        if path == home.standardizedFileURL.path { throw Rejection.homeRootItself }
        if target.pathComponents.count <= 3 { throw Rejection.tooShallow }

        // 2. Hard system denylist by absolute prefix.
        for prefix in systemPrefixes where path == prefix || path.hasPrefix(prefix + "/") {
            throw Rejection.systemPath
        }

        // 3. Protected user locations.
        for p in protectedLocations {
            if path == p.path || path.hasPrefix(p.path + "/") { throw Rejection.protectedLocation }
        }

        // 4. Must be inside (or equal to, for contents-only) an allowed root.
        guard let matchedRoot = allowedRoots.first(where: { root in
            path == root.path || path.hasPrefix(root.path + "/")
        }) else {
            throw Rejection.outsideAllowedRoots
        }

        // 5. Refuse to delete an allowed root directory itself unless we are
        //    only clearing its contents.
        if path == matchedRoot.path && !contentsOnly {
            throw Rejection.isAllowedRootItself
        }

        // 6. Resolve symlinks and confirm the *real* path still lives under an
        //    allowed root — blocks symlink-escape attacks/footguns.
        let resolvedPath = target.resolvingSymlinksInPath().standardizedFileURL.path
        let stillInside = allowedRoots.contains { root in
            resolvedPath == root.path || resolvedPath.hasPrefix(root.path + "/")
        }
        if !stillInside { throw Rejection.escapesViaSymlink }
    }

    /// Convenience boolean form.
    static func isSafe(_ url: URL, contentsOnly: Bool) -> Bool {
        (try? validate(url, contentsOnly: contentsOnly)) != nil
    }
}
