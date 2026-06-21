import Foundation

/// Discovers removable items on disk for a set of categories. Pure, stateless
/// filesystem work — safe to run off the main actor. Produces value types only.
enum Scanner {

    /// Scan every category in the catalog. `progress` is called with a 0...1
    /// fraction after each category completes (invoked on the calling task).
    static func scanAll(
        _ categories: [CleanupCategory],
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) -> ScanResult {
        var result = ScanResult()
        let total = max(categories.count, 1)
        for (index, category) in categories.enumerated() {
            // Emit the category id; the caller resolves a localized label.
            progress?(Double(index) / Double(total), category.id)
            var items: [CleanupItem] = []
            for rule in category.rules {
                items.append(contentsOf: scan(rule: rule, categoryID: category.id))
            }
            if !items.isEmpty {
                result.itemsByCategory[category.id] = items
            }
        }
        progress?(1.0, "Done")
        return result
    }

    static func scan(rule: CleanupRule, categoryID: String) -> [CleanupItem] {
        let fm = FileManager.default
        switch rule.strategy {

        case .childrenOf(let root):
            guard let entries = try? fm.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) else { return [] }

            var items: [CleanupItem] = []
            for child in entries {
                // Re-validate every single path before it can become an item.
                guard SafetyGuard.isSafe(child, contentsOnly: false) else { continue }
                let size = sizeOf(child)
                guard size > 0 else { continue }
                items.append(CleanupItem(
                    id: "\(categoryID)|\(child.path)",
                    categoryID: categoryID,
                    ruleID: rule.id,
                    displayName: child.lastPathComponent,
                    url: child,
                    clearsContentsOnly: false,
                    size: size,
                    mode: rule.defaultMode,
                    isSelected: rule.selectedByDefault
                ))
            }
            return items

        case .contentsAsOne(let root, let name):
            guard fm.fileExists(atPath: root.path) else { return [] }
            guard SafetyGuard.isSafe(root, contentsOnly: true) else { return [] }
            let size = sizeOf(root)
            guard size > 0 else { return [] }
            return [CleanupItem(
                id: "\(categoryID)|\(root.path)",
                categoryID: categoryID,
                ruleID: rule.id,
                displayName: name,
                url: root,
                clearsContentsOnly: true,
                size: size,
                mode: rule.defaultMode,
                isSelected: rule.selectedByDefault
            )]
        }
    }

    /// Recursively compute the allocated size of a file or directory. Does not
    /// follow symlinks (we never traverse out of the tree we're measuring).
    static func sizeOf(_ url: URL) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            return fileSize(url)
        }

        var total: Int64 = 0
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            total += fileSize(fileURL)
        }
        return total
    }

    private static func fileSize(_ url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }
        if let allocated = values.totalFileAllocatedSize { return Int64(allocated) }
        if let allocated = values.fileAllocatedSize { return Int64(allocated) }
        if let logical = values.fileSize { return Int64(logical) }
        return 0
    }
}
