import Foundation

struct StorageTestEngine {
    static let sectorSize = 512
    static let oneMiB: UInt64 = 1_048_576
    static let maxFileSize: UInt64 = 1_073_741_824
    static let minimumSafetyReserve: UInt64 = 128 * 1_048_576
    static let maximumSafetyReserve: UInt64 = 1_073_741_824

    static func plannedUsableBytes(from availableBytes: UInt64) -> UInt64 {
        let reserve = safetyReserveBytes(for: availableBytes)
        guard availableBytes > reserve + oneMiB else {
            return availableBytes / oneMiB * oneMiB
        }
        return (availableBytes - reserve) / oneMiB * oneMiB
    }

    static func safetyReserveBytes(for availableBytes: UInt64) -> UInt64 {
        let onePercent = availableBytes / 100
        return min(max(onePercent, minimumSafetyReserve), maximumSafetyReserve)
    }

    func run(
        configuration: TestConfiguration,
        eventHandler: @escaping @Sendable (StorageTestEvent) async -> Void
    ) async throws -> TestReport {
        let accessed = configuration.targetURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                configuration.targetURL.stopAccessingSecurityScopedResource()
            }
        }

        if configuration.mode == .writeVerify && !FileManager.default.isWritableFile(atPath: configuration.targetURL.path) {
            throw StorageTestError.targetNotWritable
        }

        switch configuration.mode {
        case .writeVerify:
            return try await writeThenVerify(configuration: configuration, eventHandler: eventHandler)
        case .verifyOnly:
            return try await verifyExistingFiles(configuration: configuration, eventHandler: eventHandler)
        }
    }

    private func writeThenVerify(
        configuration: TestConfiguration,
        eventHandler: @escaping @Sendable (StorageTestEvent) async -> Void
    ) async throws -> TestReport {
        let strings = configuration.language.strings
        let existingFiles = try H2WFileScanner.allH2WFiles(in: configuration.targetURL)
        guard existingFiles.isEmpty else {
            throw StorageTestError.existingTestFiles(existingFiles.count)
        }

        let request = try resolveRequestedBytes(configuration: configuration)
        let requestedBytes = request.bytes
        let plan = makeFilePlan(totalBytes: requestedBytes, in: configuration.targetURL)
        guard !plan.isEmpty else { throw StorageTestError.invalidSize }

        await eventHandler(.log(strings.writingTo(
            size: ByteCountFormat.fileSize(requestedBytes),
            path: configuration.targetURL.path
        )))
        if request.reservedBytes > 0 {
            await eventHandler(.log(strings.leavingFree(ByteCountFormat.fileSize(request.reservedBytes))))
        }

        var progress = TestProgress(
            phase: .writing,
            totalFiles: plan.count,
            totalBytes: requestedBytes,
            startedAt: Date(),
            statusLine: strings.writingTestFiles
        )
        let writeStart = Date()
        var progressEmitter = ProgressEmitter(eventHandler: eventHandler)

        for file in plan {
            try Task.checkCancellation()
            progress.currentFileName = file.url.lastPathComponent
            progress.currentFileIndex = file.index
            progress.currentFileBytes = file.size
            progress.currentFileCompletedBytes = 0
            progress.isSyncing = false
            progress.statusLine = strings.writingFile(index: file.index, total: plan.count)
            await progressEmitter.emit(progress, force: true)

            try await writeFile(
                file,
                strings: strings,
                progress: &progress,
                startedAt: writeStart,
                progressEmitter: &progressEmitter
            )
        }

        let writeDuration = Date().timeIntervalSince(writeStart)
        let writtenBytes = progress.writtenBytes
        await eventHandler(.log(strings.writePassFinished(duration: ByteCountFormat.duration(writeDuration))))

        var verifyReport = try await verifyFiles(
            plan,
            strings: strings,
            targetURL: configuration.targetURL,
            writeDuration: writeDuration,
            writtenBytes: writtenBytes,
            eventHandler: eventHandler
        )
        verifyReport.generatedFileCount = plan.count
        return verifyReport
    }

    private func verifyExistingFiles(
        configuration: TestConfiguration,
        eventHandler: @escaping @Sendable (StorageTestEvent) async -> Void
    ) async throws -> TestReport {
        let strings = configuration.language.strings
        let files = try H2WFileScanner.numberedFiles(in: configuration.targetURL)
        guard !files.isEmpty else { throw StorageTestError.noTestFiles }

        let plan = files.enumerated().map { offset, file in
            let startOffset = UInt64(offset) * Self.maxFileSize
            return PlannedTestFile(url: file.url, index: file.index ?? offset + 1, size: file.size, startOffset: startOffset)
        }

        await eventHandler(.log(strings.verifyingExisting(plan.count)))
        return try await verifyFiles(
            plan,
            strings: strings,
            targetURL: configuration.targetURL,
            writeDuration: 0,
            writtenBytes: 0,
            eventHandler: eventHandler
        )
    }

    private func resolveRequestedBytes(configuration: TestConfiguration) throws -> (bytes: UInt64, reservedBytes: UInt64) {
        let rawBytes: UInt64
        var reservedBytes: UInt64 = 0
        if configuration.useAllAvailableSpace {
            let values = try configuration.targetURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            let availableBytes = UInt64(max(0, values.volumeAvailableCapacity ?? 0))
            rawBytes = Self.plannedUsableBytes(from: availableBytes)
            reservedBytes = availableBytes > rawBytes ? availableBytes - rawBytes : 0
        } else {
            rawBytes = configuration.bytesToTest
        }

        let alignedBytes = rawBytes / Self.oneMiB * Self.oneMiB
        guard alignedBytes >= Self.oneMiB else { throw StorageTestError.invalidSize }
        return (alignedBytes, reservedBytes)
    }

    private func makeFilePlan(totalBytes: UInt64, in directory: URL) -> [PlannedTestFile] {
        var files: [PlannedTestFile] = []
        var remainingBytes = totalBytes
        var index = 1
        var startOffset: UInt64 = 0

        while remainingBytes > 0 {
            let fileSize = min(Self.maxFileSize, remainingBytes)
            let fileURL = directory.appendingPathComponent("\(index).h2w")
            files.append(PlannedTestFile(url: fileURL, index: index, size: fileSize, startOffset: startOffset))
            remainingBytes -= fileSize
            startOffset += fileSize
            index += 1
        }

        return files
    }

    private func writeFile(
        _ plannedFile: PlannedTestFile,
        strings: AppStrings,
        progress: inout TestProgress,
        startedAt: Date,
        progressEmitter: inout ProgressEmitter
    ) async throws {
        FileManager.default.createFile(atPath: plannedFile.url.path, contents: nil)
        let handle = try FileHandle(forWritingTo: plannedFile.url)
        defer {
            try? handle.close()
        }

        var fileOffset: UInt64 = 0
        while fileOffset < plannedFile.size {
            try Task.checkCancellation()

            let chunkSize = Int(min(Self.oneMiB, plannedFile.size - fileOffset))
            let data = TestPattern.chunk(startOffset: plannedFile.startOffset + fileOffset, byteCount: chunkSize)
            try handle.write(contentsOf: data)

            fileOffset += UInt64(chunkSize)
            progress.writtenBytes += UInt64(chunkSize)
            progress.currentFileCompletedBytes = fileOffset
            progress.lastActivityAt = Date()
            progress.isSyncing = false
            let elapsed = max(Date().timeIntervalSince(startedAt), 0.001)
            progress.writeSpeedBytesPerSecond = Double(progress.writtenBytes) / elapsed
            progress.statusLine = strings.writingFileName(plannedFile.url.lastPathComponent)
            await progressEmitter.emit(progress)
        }

        progress.isSyncing = true
        progress.statusLine = strings.flushingFileName(plannedFile.url.lastPathComponent)
        progress.lastActivityAt = Date()
        await progressEmitter.emit(progress, force: true)
        handle.synchronizeFile()
        progress.isSyncing = false
        progress.lastActivityAt = Date()
        await progressEmitter.emit(progress, force: true)
    }

    private func verifyFiles(
        _ files: [PlannedTestFile],
        strings: AppStrings,
        targetURL: URL,
        writeDuration: TimeInterval,
        writtenBytes: UInt64,
        eventHandler: @escaping @Sendable (StorageTestEvent) async -> Void
    ) async throws -> TestReport {
        let totalBytes = files.reduce(UInt64(0)) { $0 + $1.size }
        var progress = TestProgress(
            phase: .verifying,
            totalFiles: files.count,
            totalBytes: totalBytes,
            writtenBytes: writtenBytes,
            startedAt: Date(),
            statusLine: strings.verifyingTestFiles
        )
        var stats = VerificationStats()
        stats.testedBytes = totalBytes

        let verifyStart = Date()
        var progressEmitter = ProgressEmitter(eventHandler: eventHandler)
        for file in files {
            try Task.checkCancellation()
            progress.currentFileName = file.url.lastPathComponent
            progress.currentFileIndex = file.index
            progress.currentFileBytes = file.size
            progress.currentFileCompletedBytes = 0
            progress.isSyncing = false
            progress.statusLine = strings.verifyingFile(index: file.index, total: files.count)
            await progressEmitter.emit(progress, force: true)

            try await verifyFile(
                file,
                strings: strings,
                stats: &stats,
                progress: &progress,
                startedAt: verifyStart,
                progressEmitter: &progressEmitter
            )
        }

        let verifyDuration = Date().timeIntervalSince(verifyStart)
        let verdict: TestVerdict = stats.hasErrors ? .failed : .passed
        let message = stats.hasErrors ? strings.defectiveMediaMessage : strings.successMessage

        let report = TestReport(
            verdict: verdict,
            targetPath: targetURL.path,
            totalBytes: totalBytes,
            stats: stats,
            writeDuration: writeDuration,
            verifyDuration: verifyDuration,
            writeSpeedBytesPerSecond: writeDuration > 0 ? Double(writtenBytes) / writeDuration : 0,
            readSpeedBytesPerSecond: verifyDuration > 0 ? Double(totalBytes) / verifyDuration : 0,
            generatedFileCount: files.count,
            message: message
        )

        await eventHandler(.progress(TestProgress(
            phase: .finished,
            totalBytes: totalBytes,
            writtenBytes: writtenBytes,
            verifiedBytes: totalBytes,
            writeSpeedBytesPerSecond: report.writeSpeedBytesPerSecond,
            readSpeedBytesPerSecond: report.readSpeedBytesPerSecond,
            startedAt: progress.startedAt,
            statusLine: message
        )))
        await eventHandler(.report(report))
        return report
    }

    private func verifyFile(
        _ plannedFile: PlannedTestFile,
        strings: AppStrings,
        stats: inout VerificationStats,
        progress: inout TestProgress,
        startedAt: Date,
        progressEmitter: inout ProgressEmitter
    ) async throws {
        let handle = try FileHandle(forReadingFrom: plannedFile.url)
        defer {
            try? handle.close()
        }

        var fileOffset: UInt64 = 0
        while fileOffset < plannedFile.size {
            try Task.checkCancellation()

            let expectedCount = Int(min(Self.oneMiB, plannedFile.size - fileOffset))
            let actualData = try handle.read(upToCount: expectedCount) ?? Data()
            let expectedData = TestPattern.chunk(startOffset: plannedFile.startOffset + fileOffset, byteCount: expectedCount)

            compare(
                actual: actualData,
                expected: expectedData,
                baseOffset: plannedFile.startOffset + fileOffset,
                expectedCount: expectedCount,
                stats: &stats
            )

            fileOffset += UInt64(expectedCount)
            progress.verifiedBytes += UInt64(expectedCount)
            progress.currentFileCompletedBytes = fileOffset
            progress.lastActivityAt = Date()
            let elapsed = max(Date().timeIntervalSince(startedAt), 0.001)
            progress.readSpeedBytesPerSecond = Double(progress.verifiedBytes) / elapsed
            progress.statusLine = strings.verifyingFileName(plannedFile.url.lastPathComponent)
            await progressEmitter.emit(progress)
        }
        await progressEmitter.emit(progress, force: true)
    }

    private func compare(
        actual: Data,
        expected: Data,
        baseOffset: UInt64,
        expectedCount: Int,
        stats: inout VerificationStats
    ) {
        let comparableCount = min(actual.count, expected.count)

        actual.withUnsafeBytes { actualRaw in
            expected.withUnsafeBytes { expectedRaw in
                guard let actualBase = actualRaw.bindMemory(to: UInt8.self).baseAddress,
                      let expectedBase = expectedRaw.bindMemory(to: UInt8.self).baseAddress else {
                    return
                }

                var sectorStart = 0
                while sectorStart < comparableCount {
                    let sectorCount = min(Self.sectorSize, comparableCount - sectorStart)
                    var differingBits = 0
                    var firstMismatch: Int?

                    for index in 0..<sectorCount {
                        let actualByte = actualBase[sectorStart + index]
                        let expectedByte = expectedBase[sectorStart + index]
                        if actualByte != expectedByte {
                            if firstMismatch == nil {
                                firstMismatch = index
                            }
                            differingBits += Int((actualByte ^ expectedByte).nonzeroBitCount)
                        }
                    }

                    if differingBits == 0 {
                        stats.okBytes += UInt64(sectorCount)
                    } else {
                        let sectorOffset = baseOffset + UInt64(sectorStart)
                        let foundOffset = sectorCount >= 8 ? readUInt64LE(from: actualBase + sectorStart, available: sectorCount) : 0

                        if foundOffset != sectorOffset && foundOffset % UInt64(Self.sectorSize) == 0 {
                            stats.overwrittenSectors += 1
                            stats.aliasedOffsets.insert(foundOffset)
                        } else if differingBits < 8 {
                            stats.slightlyChangedSectors += 1
                        } else {
                            stats.corruptedSectors += 1
                        }

                        if stats.firstError == nil {
                            let mismatch = firstMismatch ?? 0
                            let wordStart = sectorStart + (mismatch / 8) * 8
                            let actualAvailable = max(0, comparableCount - wordStart)
                            let expectedAvailable = max(0, expected.count - wordStart)
                            stats.firstError = FirstError(
                                offset: baseOffset + UInt64(wordStart),
                                expectedWord: readUInt64LE(from: expectedBase + wordStart, available: expectedAvailable),
                                foundWord: readUInt64LE(from: actualBase + wordStart, available: actualAvailable)
                            )
                        }
                    }

                    sectorStart += Self.sectorSize
                }
            }
        }

        if actual.count < expectedCount {
            let missingBytes = UInt64(expectedCount - actual.count)
            stats.lostBytes += missingBytes
            stats.corruptedSectors += (missingBytes + UInt64(Self.sectorSize) - 1) / UInt64(Self.sectorSize)
            if stats.firstError == nil {
                stats.firstError = FirstError(offset: baseOffset + UInt64(actual.count), expectedWord: 0, foundWord: 0)
            }
        }
    }

    private func readUInt64LE(from pointer: UnsafePointer<UInt8>, available: Int = 8) -> UInt64 {
        var value: UInt64 = 0
        for index in 0..<min(8, available) {
            value |= UInt64(pointer[index]) << UInt64(index * 8)
        }
        return value
    }
}

private struct PlannedTestFile {
    var url: URL
    var index: Int
    var size: UInt64
    var startOffset: UInt64
}

private struct ProgressEmitter {
    private let interval: TimeInterval = 0.5
    private var lastEmit = Date.distantPast
    private let eventHandler: @Sendable (StorageTestEvent) async -> Void

    init(eventHandler: @escaping @Sendable (StorageTestEvent) async -> Void) {
        self.eventHandler = eventHandler
    }

    mutating func emit(_ progress: TestProgress, force: Bool = false) async {
        let now = Date()
        guard force || now.timeIntervalSince(lastEmit) >= interval else { return }
        lastEmit = now
        await eventHandler(.progress(progress))
    }
}

private enum TestPattern {
    static func chunk(startOffset: UInt64, byteCount: Int) -> Data {
        var data = Data(count: byteCount)
        data.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }

            var offset = startOffset
            var sectorStart = 0
            while sectorStart < byteCount {
                let sectorCount = min(StorageTestEngine.sectorSize, byteCount - sectorStart)
                writeUInt64LE(offset, to: baseAddress + sectorStart)

                var generator = SplitMix64(seed: offset ^ 0x5452_5545_4259_5445)
                var cursor = sectorStart + 8
                let sectorEnd = sectorStart + sectorCount
                while cursor < sectorEnd {
                    let value = generator.next()
                    var shift = 0
                    while shift < 64 && cursor < sectorEnd {
                        baseAddress[cursor] = UInt8(truncatingIfNeeded: value >> UInt64(shift))
                        cursor += 1
                        shift += 8
                    }
                }

                offset += UInt64(StorageTestEngine.sectorSize)
                sectorStart += StorageTestEngine.sectorSize
            }
        }
        return data
    }

    private static func writeUInt64LE(_ value: UInt64, to pointer: UnsafeMutablePointer<UInt8>) {
        for index in 0..<8 {
            pointer[index] = UInt8(truncatingIfNeeded: value >> UInt64(index * 8))
        }
    }
}

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
        value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
        return value ^ (value >> 31)
    }
}
