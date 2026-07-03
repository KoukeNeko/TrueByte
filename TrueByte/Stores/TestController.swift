import AppKit
import Combine
import Foundation

@MainActor
final class TestController: ObservableObject {
    @Published var targetInfo: TargetVolumeInfo?
    @Published var mode: TestMode = .writeVerify
    @Published var useAllAvailableSpace = false
    @Published var customSizeGiB: Double = 1
    @Published var progress = TestProgress()
    @Published var report = TestReport()
    @Published var logEntries: [TestLogEntry] = []
    @Published var errorMessage: String?
    @Published var language: AppLanguage = AppLanguage.defaultLanguage {
        didSet {
            refreshLocalizedStaticText()
        }
    }

    private var currentTask: Task<Void, Never>?

    private var strings: AppStrings {
        language.strings
    }

    var isRunning: Bool {
        currentTask != nil
    }

    var canStart: Bool {
        targetInfo != nil && !isRunning
    }

    var customBytes: UInt64 {
        let bytes = max(customSizeGiB, 0) * 1_073_741_824
        return UInt64(bytes)
    }

    var plannedTestBytes: UInt64 {
        guard let targetInfo else { return customBytes }

        switch mode {
        case .writeVerify:
            guard useAllAvailableSpace else { return customBytes }
            return StorageTestEngine.plannedUsableBytes(from: targetInfo.availableBytes ?? 0)
        case .verifyOnly:
            return targetInfo.h2wBytes
        }
    }

    var plannedReserveBytes: UInt64 {
        guard mode == .writeVerify,
              useAllAvailableSpace,
              let availableBytes = targetInfo?.availableBytes else {
            return 0
        }
        let planned = StorageTestEngine.plannedUsableBytes(from: availableBytes)
        return availableBytes > planned ? availableBytes - planned : 0
    }

    func selectTarget() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = strings.openPanelPrompt
        panel.message = strings.openPanelMessage

        if panel.runModal() == .OK, let url = panel.url {
            setTarget(url)
        }
    }

    func startWriteVerify() {
        mode = .writeVerify
        start()
    }

    func startVerifyOnly() {
        mode = .verifyOnly
        start()
    }

    func start() {
        guard let targetInfo else {
            errorMessage = strings.storageError(.noTarget)
            return
        }
        guard !isRunning else { return }

        errorMessage = nil
        report = TestReport(message: strings.noTestHasRun)
        logEntries.removeAll()
        progress = TestProgress(
            phase: mode == .verifyOnly ? .verifying : .writing,
            totalBytes: initialTotalBytes(for: targetInfo),
            startedAt: Date(),
            lastActivityAt: Date(),
            statusLine: strings.title(for: mode)
        )

        let configuration = TestConfiguration(
            targetURL: targetInfo.url,
            mode: mode,
            bytesToTest: customBytes,
            useAllAvailableSpace: useAllAvailableSpace,
            language: language
        )
        currentTask = Task.detached(priority: .userInitiated) { [weak self, configuration] in
            let engine = StorageTestEngine()
            do {
                _ = try await engine.run(configuration: configuration) { [weak self] event in
                    await self?.receive(event)
                }
                await MainActor.run { [weak self] in
                    self?.refreshTarget()
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.progress.phase = .cancelled
                    self.report.verdict = .cancelled
                    self.report.message = self.strings.testCancelled
                    self.progress.statusLine = self.strings.cancelled
                    self.log(self.strings.testCancelled)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let message = self.strings.message(for: error)
                    self.progress.phase = .failed
                    self.progress.statusLine = message
                    self.errorMessage = message
                    self.report.verdict = .failed
                    self.report.message = message
                    self.log(message)
                }
            }
            await MainActor.run { [weak self] in
                self?.currentTask = nil
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        progress.phase = .cancelled
        progress.statusLine = strings.cancelled
    }

    func clearTestFiles() {
        guard let targetInfo, !isRunning else { return }

        let alert = NSAlert()
        alert.messageText = strings.deleteH2WTitle
        alert.informativeText = strings.deleteH2WMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: strings.delete)
        alert.addButton(withTitle: strings.cancel)

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        do {
            let accessed = targetInfo.url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    targetInfo.url.stopAccessingSecurityScopedResource()
                }
            }

            let files = try H2WFileScanner.allH2WFiles(in: targetInfo.url)
            for file in files {
                try FileManager.default.removeItem(at: file.url)
            }
            log(strings.deletedFiles(files.count))
            refreshTarget()
        } catch {
            let message = strings.message(for: error)
            errorMessage = message
            log(message)
        }
    }

    func refreshTarget() {
        guard let url = targetInfo?.url else { return }
        setTarget(url)
    }

    private func setTarget(_ url: URL) {
        do {
            targetInfo = try Self.volumeInfo(for: url)
            progress.statusLine = strings.ready
            errorMessage = nil
        } catch {
            let message = strings.message(for: error)
            errorMessage = message
            log(message)
        }
    }

    private func receive(_ event: StorageTestEvent) {
        switch event {
        case .progress(let newProgress):
            progress = newProgress
        case .log(let message):
            log(message)
        case .report(let newReport):
            report = newReport
        }
    }

    private func log(_ message: String) {
        logEntries.insert(TestLogEntry(message: message), at: 0)
        if logEntries.count > 80 {
            logEntries.removeLast(logEntries.count - 80)
        }
    }

    private func refreshLocalizedStaticText() {
        if progress.phase == .idle {
            progress.statusLine = targetInfo == nil ? strings.selectTargetStatus : strings.ready
        }
        if report.verdict == .notRun {
            report.message = strings.noTestHasRun
        }
    }

    private func initialTotalBytes(for targetInfo: TargetVolumeInfo) -> UInt64 {
        switch mode {
        case .writeVerify:
            guard useAllAvailableSpace else { return customBytes }
            return StorageTestEngine.plannedUsableBytes(from: targetInfo.availableBytes ?? 0)
        case .verifyOnly:
            return targetInfo.h2wBytes
        }
    }

    private static func volumeInfo(for url: URL) throws -> TargetVolumeInfo {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let values = try url.resourceValues(forKeys: [
            .localizedNameKey,
            .volumeLocalizedNameKey,
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey,
            .volumeIsReadOnlyKey
        ])
        let h2wFiles = try H2WFileScanner.allH2WFiles(in: url)
        let h2wBytes = h2wFiles.reduce(UInt64(0)) { $0 + $1.size }

        return TargetVolumeInfo(
            url: url,
            displayName: values.volumeLocalizedName ?? values.localizedName ?? url.lastPathComponent,
            availableBytes: values.volumeAvailableCapacity.map { UInt64(max(0, $0)) },
            totalBytes: values.volumeTotalCapacity.map { UInt64(max(0, $0)) },
            isReadOnly: values.volumeIsReadOnly ?? false,
            h2wFileCount: h2wFiles.count,
            h2wBytes: h2wBytes
        )
    }
}
