import Foundation
import Observation

@MainActor
@Observable
final class SweepModel {

    enum Phase: Equatable {
        case idle
        case scanning(progress: Double, label: String)
        case scanned
        case cleaning(progress: Double, label: String)
        case done(deleted: Int64, trashed: Int64, failures: Int)
    }

    let categories = CleanupCatalog.categories

    private(set) var phase: Phase = .idle
    private(set) var result = ScanResult()
    var selection: [String: CleanupItem] = [:]   // keyed by item.id

    private(set) var memory = MemoryMonitor.snapshot()
    private(set) var disk = SystemInfo.disk()
    var purgeMessage: String?

    /// Drives the pre-clean confirmation dialog.
    var confirmCleanPresented = false

    // MARK: - Derived

    var isBusy: Bool {
        switch phase {
        case .scanning, .cleaning: return true
        default: return false
        }
    }

    var hasScanned: Bool {
        switch phase {
        case .scanned, .done: return true
        default: return false
        }
    }

    var selectedItems: [CleanupItem] {
        selection.values.filter { $0.isSelected }
    }

    var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    /// True when any selected item would be removed permanently (not trashed).
    var selectionHasPermanentDelete: Bool {
        selectedItems.contains { $0.mode == .delete }
    }

    func items(for categoryID: String) -> [CleanupItem] {
        result.items(for: categoryID).map { selection[$0.id] ?? $0 }
    }

    func categorySize(_ categoryID: String) -> Int64 {
        result.totalSize(for: categoryID)
    }

    func selectedCount(in categoryID: String) -> Int {
        items(for: categoryID).filter { $0.isSelected }.count
    }

    // MARK: - Selection mutation

    func toggle(_ item: CleanupItem) {
        var copy = selection[item.id] ?? item
        copy.isSelected.toggle()
        selection[item.id] = copy
    }

    func setMode(_ mode: RemovalMode, for item: CleanupItem) {
        var copy = selection[item.id] ?? item
        copy.mode = mode
        selection[item.id] = copy
    }

    func setAll(in categoryID: String, selected: Bool) {
        for item in items(for: categoryID) {
            var copy = selection[item.id] ?? item
            copy.isSelected = selected
            selection[item.id] = copy
        }
    }

    // MARK: - Actions

    func refreshMemory() {
        memory = MemoryMonitor.snapshot()
    }

    func refreshDisk() {
        disk = SystemInfo.disk()
    }

    /// Ask for confirmation before cleaning. The UI presents a dialog; the
    /// actual removal only happens when the user confirms via `clean()`.
    func requestClean() {
        guard hasScanned, !isBusy, !selectedItems.isEmpty else { return }
        confirmCleanPresented = true
    }

    func scan() {
        guard !isBusy else { return }
        phase = .scanning(progress: 0, label: "")
        let cats = categories

        Task {
            let scanned = await Task.detached(priority: .userInitiated) {
                Scanner.scanAll(cats) { fraction, categoryID in
                    Task { @MainActor in
                        let label = self.localizedCategoryName(categoryID)
                        self.phase = .scanning(progress: fraction, label: label)
                    }
                }
            }.value

            self.result = scanned
            // Seed selection from scan defaults.
            var seed: [String: CleanupItem] = [:]
            for item in scanned.allItems { seed[item.id] = item }
            self.selection = seed
            self.phase = .scanned
            self.refreshMemory()
            self.refreshDisk()
        }
    }

    private func localizedCategoryName(_ id: String) -> String {
        guard let category = categories.first(where: { $0.id == id }) else { return "" }
        return Localizer.shared.name(category)
    }

    func clean() {
        guard hasScanned, !isBusy else { return }
        let toClean = selectedItems
        guard !toClean.isEmpty else { return }
        confirmCleanPresented = false
        phase = .cleaning(progress: 0, label: "")

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                Cleaner.clean(toClean) { fraction, label in
                    Task { @MainActor in
                        self.phase = .cleaning(progress: fraction, label: label)
                    }
                }
            }.value

            // Drop cleaned items from the displayed result.
            let cleanedIDs = Set(report.outcomes.filter { $0.succeeded }.map { $0.item.id })
            for (cat, items) in self.result.itemsByCategory {
                self.result.itemsByCategory[cat] = items.filter { !cleanedIDs.contains($0.id) }
            }
            for id in cleanedIDs { self.selection[id] = nil }

            self.phase = .done(deleted: report.deletedBytes,
                               trashed: report.trashedBytes,
                               failures: report.failures.count)
            self.refreshMemory()
            self.refreshDisk()
        }
    }

    func purgeMemory() {
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                MemoryMonitor.purgeInactive()
            }.value
            let loc = Localizer.shared
            switch result {
            case .success:       self.purgeMessage = loc.string(.purgedOK)
            case .needsAdmin:    self.purgeMessage = loc.string(.purgeNeedsAdmin)
            case .failed(let m): self.purgeMessage = loc.purgeFailed(m)
            }
            self.refreshMemory()
        }
    }

    func reset() {
        phase = .scanned
    }
}
