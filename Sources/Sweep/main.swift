import Foundation

// Entry point. A hidden, read-only `--dryrun` mode scans and prints what *would*
// be cleaned without touching anything — handy for verification and CI. Anything
// else launches the GUI.
if CommandLine.arguments.contains("--dryrun") {
    exit(DryRun.run())
}
SweepApp.main()

enum DryRun {
    /// Returns a process exit code: 0 if all self-checks pass, 1 otherwise.
    @discardableResult
    static func run() -> Int32 {
        var ok = true
        print("Sweep — dry run (read-only, nothing will be removed)\n")

        // Report which safe roots actually exist on this machine.
        print("Allowed roots:")
        for root in SafetyGuard.allowedRoots {
            let exists = FileManager.default.fileExists(atPath: root.path)
            print("  [\(exists ? "x" : " ")] \(root.path)")
        }
        print("")

        let result = Scanner.scanAll(CleanupCatalog.categories) { fraction, label in
            FileHandle.standardError.write("scanning \(Int(fraction * 100))% \(label)\r".data(using: .utf8)!)
        }
        FileHandle.standardError.write("\n".data(using: .utf8)!)

        for category in CleanupCatalog.categories {
            let items = result.items(for: category.id)
            guard !items.isEmpty else { continue }
            let name = Strings.value(category.nameKey, .en)
            print("▸ \(name) — \(Format.size(result.totalSize(for: category.id)))")
            for item in items.prefix(8) {
                let mark = item.clearsContentsOnly ? "(contents)" : ""
                print("    \(Format.size(item.size).padding(toLength: 10, withPad: " ", startingAt: 0)) \(item.displayName) \(mark)")
            }
            if items.count > 8 { print("    … and \(items.count - 8) more") }
        }

        // Sanity-check the safety gate against paths that must always be rejected.
        print("\nSafety self-check (all must say BLOCKED):")
        let home = FileManager.default.homeDirectoryForCurrentUser
        let mustReject: [URL] = [
            home,
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop/important.txt"),
            URL(fileURLWithPath: "/System/Library"),
            URL(fileURLWithPath: "/usr/bin"),
            home.appendingPathComponent("Library/Keychains"),
            home.appendingPathComponent("Library/Developer/Xcode/Archives"),
            home.appendingPathComponent("Library"),
        ]
        for url in mustReject {
            let blocked = !SafetyGuard.isSafe(url, contentsOnly: false)
            if !blocked { ok = false }
            print("  [\(blocked ? "BLOCKED" : "ALLOWED ⚠️")] \(url.path)")
        }

        print("\nTotal reclaimable: \(Format.size(result.grandTotal))")

        // Localization completeness: every key must have a non-empty ru + en.
        print("\nLocalization check:")
        var missing: [String] = []
        for key in LocKey.allCases {
            guard let pair = Strings.table[key] else { missing.append("\(key) (no entry)"); continue }
            if pair.ru.isEmpty { missing.append("\(key) (ru empty)") }
            if pair.en.isEmpty { missing.append("\(key) (en empty)") }
        }
        if missing.isEmpty {
            print("  [OK] all \(LocKey.allCases.count) keys translated (ru + en)")
        } else {
            ok = false
            print("  [FAIL] missing translations:")
            for m in missing { print("    - \(m)") }
        }

        print("\n\(ok ? "✓ All self-checks passed." : "✗ Self-checks FAILED.")")
        return ok ? 0 : 1
    }
}
