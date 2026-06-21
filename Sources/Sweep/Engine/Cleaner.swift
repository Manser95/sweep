import Foundation

/// Performs the actual removal of selected items. Every path is validated by
/// `SafetyGuard` one final time immediately before it is touched — the UI
/// selection state is never trusted on its own.
enum Cleaner {

    struct ItemOutcome: Sendable {
        let item: CleanupItem
        let freed: Int64
        let error: String?
        var succeeded: Bool { error == nil }
    }

    struct Report: Sendable {
        var outcomes: [ItemOutcome] = []
        var totalProcessed: Int64 { outcomes.reduce(0) { $0 + $1.freed } }
        /// Space reclaimed immediately (permanent deletes).
        var deletedBytes: Int64 {
            outcomes.filter { $0.item.mode == .delete }.reduce(0) { $0 + $1.freed }
        }
        /// Space moved to the Trash — only reclaimed once the Trash is emptied.
        var trashedBytes: Int64 {
            outcomes.filter { $0.item.mode == .trash }.reduce(0) { $0 + $1.freed }
        }
        var failures: [ItemOutcome] { outcomes.filter { !$0.succeeded } }
        var successCount: Int { outcomes.filter { $0.succeeded }.count }
    }

    /// Remove the given items. `progress` reports a 0...1 fraction and the name
    /// of the item just processed.
    static func clean(
        _ items: [CleanupItem],
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) -> Report {
        var report = Report()
        let total = max(items.count, 1)

        for (index, item) in items.enumerated() {
            let outcome = remove(item)
            report.outcomes.append(outcome)
            progress?(Double(index + 1) / Double(total), item.displayName)
        }
        return report
    }

    private static func remove(_ item: CleanupItem) -> ItemOutcome {
        let fm = FileManager.default

        // FINAL gate: never trust the item — re-validate the live path.
        do {
            try SafetyGuard.validate(item.url, contentsOnly: item.clearsContentsOnly)
        } catch {
            return ItemOutcome(item: item, freed: 0, error: "Blocked by safety check: \(error)")
        }

        do {
            if item.clearsContentsOnly {
                // Remove each child but keep the container directory intact.
                let children = try fm.contentsOfDirectory(
                    at: item.url,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                var freed: Int64 = 0
                var firstError: String?
                for child in children {
                    // Children inherit safety: they sit under a validated root.
                    let childSize = Scanner.sizeOf(child)
                    do {
                        try perform(mode: item.mode, on: child, fm: fm)
                        freed += childSize
                    } catch {
                        if firstError == nil { firstError = error.localizedDescription }
                    }
                }
                return ItemOutcome(item: item, freed: freed, error: firstError)
            } else {
                let size = Scanner.sizeOf(item.url)
                try perform(mode: item.mode, on: item.url, fm: fm)
                return ItemOutcome(item: item, freed: size, error: nil)
            }
        } catch {
            return ItemOutcome(item: item, freed: 0, error: error.localizedDescription)
        }
    }

    private static func perform(mode: RemovalMode, on url: URL, fm: FileManager) throws {
        switch mode {
        case .trash:
            try fm.trashItem(at: url, resultingItemURL: nil)
        case .delete:
            try fm.removeItem(at: url)
        }
    }
}
