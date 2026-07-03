import Foundation

enum TestMode: String, CaseIterable, Identifiable, Sendable {
    case writeVerify
    case verifyOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .writeVerify: "Write + Verify"
        case .verifyOnly: "Verify Only"
        }
    }
}

enum TestPhase: Equatable, Sendable {
    case idle
    case writing
    case verifying
    case cancelling
    case finished
    case failed
    case cancelled

    var title: String {
        switch self {
        case .idle: "Ready"
        case .writing: "Writing"
        case .verifying: "Verifying"
        case .cancelling: "Stopping"
        case .finished: "Finished"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

enum TestProgressStatus: Sendable {
    case selectTarget
    case ready
    case mode(TestMode)
    case writingTestFiles
    case writingFile(index: Int, total: Int)
    case writingFileName(String)
    case flushingFileName(String)
    case verifyingTestFiles
    case verifyingFile(index: Int, total: Int)
    case verifyingFileName(String)
    case cancelling
    case success
    case defective
    case cancelled
    case storageError(StorageTestError)
    case custom(String)

    func localized(strings: AppStrings) -> String {
        switch self {
        case .selectTarget:
            strings.selectTargetStatus
        case .ready:
            strings.ready
        case .mode(let mode):
            strings.title(for: mode)
        case .writingTestFiles:
            strings.writingTestFiles
        case .writingFile(let index, let total):
            strings.writingFile(index: index, total: total)
        case .writingFileName(let name):
            strings.writingFileName(name)
        case .flushingFileName(let name):
            strings.flushingFileName(name)
        case .verifyingTestFiles:
            strings.verifyingTestFiles
        case .verifyingFile(let index, let total):
            strings.verifyingFile(index: index, total: total)
        case .verifyingFileName(let name):
            strings.verifyingFileName(name)
        case .cancelling:
            strings.cancelling
        case .success:
            strings.successMessage
        case .defective:
            strings.defectiveMediaMessage
        case .cancelled:
            strings.cancelled
        case .storageError(let error):
            strings.storageError(error)
        case .custom(let message):
            message
        }
    }
}

struct TargetVolumeInfo: Sendable {
    var url: URL
    var displayName: String
    var availableBytes: UInt64?
    var totalBytes: UInt64?
    var isReadOnly: Bool
    var h2wFileCount: Int
    var h2wBytes: UInt64
}

struct TestConfiguration: Sendable {
    var targetURL: URL
    var mode: TestMode
    var bytesToTest: UInt64
    var useAllAvailableSpace: Bool
    var language: AppLanguage
}

struct TestProgress: Sendable {
    var phase: TestPhase = .idle
    var currentFileName: String = ""
    var currentFileIndex: Int = 0
    var totalFiles: Int = 0
    var currentFileBytes: UInt64 = 0
    var currentFileCompletedBytes: UInt64 = 0
    var totalBytes: UInt64 = 0
    var writtenBytes: UInt64 = 0
    var verifiedBytes: UInt64 = 0
    var writeSpeedBytesPerSecond: Double = 0
    var readSpeedBytesPerSecond: Double = 0
    var startedAt: Date?
    var lastActivityAt = Date()
    var isSyncing = false
    var statusLine: String = "Select a target"
    var status: TestProgressStatus = .selectTarget

    var activeBytes: UInt64 {
        switch phase {
        case .writing: writtenBytes
        case .verifying: verifiedBytes
        default: max(writtenBytes, verifiedBytes)
        }
    }

    var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, Double(activeBytes) / Double(totalBytes))
    }

    var fileFractionCompleted: Double {
        guard currentFileBytes > 0 else { return 0 }
        return min(1, Double(currentFileCompletedBytes) / Double(currentFileBytes))
    }

    var activeSpeedBytesPerSecond: Double {
        switch phase {
        case .writing: writeSpeedBytesPerSecond
        case .verifying: readSpeedBytesPerSecond
        default: max(writeSpeedBytesPerSecond, readSpeedBytesPerSecond)
        }
    }

    func localizedStatusLine(strings: AppStrings) -> String {
        status.localized(strings: strings)
    }
}

enum TestVerdict: Sendable {
    case notRun
    case passed
    case failed
    case cancelled

    var title: String {
        switch self {
        case .notRun: "No Result"
        case .passed: "Passed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

struct VerificationStats: Sendable {
    var testedBytes: UInt64 = 0
    var okBytes: UInt64 = 0
    var lostBytes: UInt64 = 0
    var overwrittenSectors: UInt64 = 0
    var slightlyChangedSectors: UInt64 = 0
    var corruptedSectors: UInt64 = 0
    var aliasedOffsets = Set<UInt64>()
    var firstError: FirstError?

    var hasErrors: Bool {
        lostBytes > 0 || overwrittenSectors > 0 || slightlyChangedSectors > 0 || corruptedSectors > 0
    }

    var aliasedBytes: UInt64 {
        UInt64(aliasedOffsets.count) * UInt64(StorageTestEngine.sectorSize)
    }
}

struct FirstError: Sendable {
    var offset: UInt64
    var expectedWord: UInt64
    var foundWord: UInt64
}

enum TestReportMessage: Sendable {
    case noTestHasRun
    case cancelled
    case success
    case defective
    case storageError(StorageTestError)
    case custom(String)

    func localized(strings: AppStrings) -> String {
        switch self {
        case .noTestHasRun:
            strings.noTestHasRun
        case .cancelled:
            strings.testCancelled
        case .success:
            strings.successMessage
        case .defective:
            strings.defectiveMediaMessage
        case .storageError(let error):
            strings.storageError(error)
        case .custom(let message):
            message
        }
    }
}

struct TestReport: Sendable {
    var verdict: TestVerdict = .notRun
    var targetPath: String = ""
    var totalBytes: UInt64 = 0
    var stats = VerificationStats()
    var writeDuration: TimeInterval = 0
    var verifyDuration: TimeInterval = 0
    var writeSpeedBytesPerSecond: Double = 0
    var readSpeedBytesPerSecond: Double = 0
    var generatedFileCount: Int = 0
    var message: String = "No test has run yet."
    var messageKind: TestReportMessage = .noTestHasRun

    func localizedMessage(strings: AppStrings) -> String {
        messageKind.localized(strings: strings)
    }
}

enum StorageTestError: LocalizedError, Sendable {
    case targetNotWritable
    case noTarget
    case noTestFiles
    case invalidSize
    case existingTestFiles(Int)
    case unableToAccessSecurityScope

    var errorDescription: String? {
        switch self {
        case .targetNotWritable:
            return "The selected target is read-only."
        case .noTarget:
            return "No target folder selected."
        case .noTestFiles:
            return "No numbered .h2w files were found."
        case .invalidSize:
            return "The requested test size must be at least 1 MiB."
        case .existingTestFiles(let count):
            return "\(count) existing .h2w file(s) are already in the target."
        case .unableToAccessSecurityScope:
            return "macOS did not grant access to the selected target."
        }
    }
}

enum TestLogMessage: Sendable {
    case writingTo(size: String, path: String)
    case leavingFree(String)
    case writePassFinished(duration: String)
    case verifyingExisting(Int)
    case testCancelled
    case deletingH2WFiles
    case deletedFiles(Int)
    case storageError(StorageTestError)
    case custom(String)

    func localized(strings: AppStrings) -> String {
        switch self {
        case .writingTo(let size, let path):
            strings.writingTo(size: size, path: path)
        case .leavingFree(let size):
            strings.leavingFree(size)
        case .writePassFinished(let duration):
            strings.writePassFinished(duration: duration)
        case .verifyingExisting(let count):
            strings.verifyingExisting(count)
        case .testCancelled:
            strings.testCancelled
        case .deletingH2WFiles:
            strings.deletingH2WFiles
        case .deletedFiles(let count):
            strings.deletedFiles(count)
        case .storageError(let error):
            strings.storageError(error)
        case .custom(let message):
            message
        }
    }
}

struct TestLogEntry: Identifiable, Sendable {
    var id = UUID()
    var date = Date()
    var message: String
    var messageKind: TestLogMessage

    init(message: String) {
        self.message = message
        self.messageKind = .custom(message)
    }

    init(messageKind: TestLogMessage, strings: AppStrings) {
        self.message = messageKind.localized(strings: strings)
        self.messageKind = messageKind
    }

    func localizedMessage(strings: AppStrings) -> String {
        messageKind.localized(strings: strings)
    }
}

enum StorageTestEvent: Sendable {
    case progress(TestProgress)
    case log(TestLogMessage)
    case report(TestReport)
}
