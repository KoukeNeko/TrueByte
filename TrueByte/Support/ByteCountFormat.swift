import Foundation

enum ByteCountFormat {
    static func fileSize(_ bytes: UInt64?) -> String {
        guard let bytes else { return "Unknown" }
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else { return "0 MB/s" }
        let text = formatter.string(fromByteCount: Int64(bytesPerSecond))
        return "\(text)/s"
    }

    static func duration(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval > 0 else { return "0s" }
        let seconds = Int(interval.rounded())
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(remainingSeconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }

    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
}
