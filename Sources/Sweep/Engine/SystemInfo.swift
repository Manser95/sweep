import Foundation

struct DiskInfo: Sendable {
    let total: Int64
    let free: Int64

    var used: Int64 { max(0, total - free) }
    var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
}

enum SystemInfo {
    /// Free / total capacity of the boot volume. Uses the "important usage"
    /// available-capacity key, which reflects what the user can realistically
    /// reclaim (matches Finder's "Available").
    static func disk() -> DiskInfo {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return DiskInfo(total: 0, free: 0)
        }
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = values.volumeAvailableCapacityForImportantUsage
            ?? Int64(values.volumeAvailableCapacity ?? 0)
        return DiskInfo(total: total, free: free)
    }
}
