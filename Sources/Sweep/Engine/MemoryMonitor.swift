import Foundation
import Darwin

/// Reads live RAM statistics and exposes an honest "free inactive memory"
/// action. Note: unlike disk cleanup, you cannot meaningfully "clean" RAM by
/// deleting files — macOS manages it. The most we can do is ask the kernel to
/// purge inactive/compressible pages via the `purge` tool.
struct MemorySnapshot: Sendable {
    let total: Int64
    let used: Int64        // active + wired + compressed
    let appMemory: Int64   // active + inactive (internal pages)
    let wired: Int64
    let compressed: Int64
    let free: Int64
    /// 0...1 memory pressure proxy.
    let pressure: Double
}

enum MemoryMonitor {

    static func snapshot() -> MemorySnapshot {
        var total: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &total, &size, nil, 0)

        let host = mach_host_self()

        var pageSize: vm_size_t = 0
        host_page_size(host, &pageSize)
        if pageSize == 0 { pageSize = vm_size_t(sysconf(Int32(_SC_PAGESIZE))) }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemorySnapshot(total: Int64(total), used: 0, appMemory: 0,
                                  wired: 0, compressed: 0, free: Int64(total), pressure: 0)
        }

        func bytes(_ pages: UInt32) -> Int64 { Int64(pages) * Int64(pageSize) }

        let active     = bytes(stats.active_count)
        let inactive   = bytes(stats.inactive_count)
        let wired      = bytes(stats.wire_count)
        let compressed = bytes(stats.compressor_page_count)
        let free       = bytes(stats.free_count)

        let used = active + wired + compressed
        let totalI = Int64(total)
        let pressure = totalI > 0 ? min(1.0, Double(used) / Double(totalI)) : 0

        return MemorySnapshot(
            total: totalI,
            used: used,
            appMemory: active + inactive,
            wired: wired,
            compressed: compressed,
            free: free,
            pressure: pressure
        )
    }

    enum PurgeResult: Sendable {
        case success
        case needsAdmin
        case failed(String)
    }

    /// Attempt to purge inactive memory. The `purge` binary typically needs no
    /// privileges on modern macOS; if it does, we report that honestly instead
    /// of silently failing.
    static func purgeInactive() -> PurgeResult {
        let candidates = ["/usr/sbin/purge", "/usr/bin/purge"]
        guard let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return .failed("`purge` command not found on this system.")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        let stderr = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 { return .success }
            let data = stderr.fileHandleForReading.readDataToEndOfFile()
            let msg = String(data: data, encoding: .utf8) ?? ""
            if msg.lowercased().contains("permission") || process.terminationStatus == 1 {
                return .needsAdmin
            }
            return .failed(msg.isEmpty ? "purge exited with code \(process.terminationStatus)" : msg)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
