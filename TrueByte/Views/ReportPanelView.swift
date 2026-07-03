import SwiftUI

struct ReportPanelView: View {
    var report: TestReport
    var logEntries: [TestLogEntry]
    var strings: AppStrings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Label(strings.title(for: report.verdict), systemImage: verdictIcon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(verdictColor)
                    Spacer()
                    Text(ByteCountFormat.fileSize(report.totalBytes))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Text(report.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    GridRow {
                        ReportValue(title: strings.ok, value: ByteCountFormat.fileSize(report.stats.okBytes))
                        ReportValue(title: strings.dataLost, value: ByteCountFormat.fileSize(report.stats.lostBytes))
                        ReportValue(title: strings.aliased, value: ByteCountFormat.fileSize(report.stats.aliasedBytes))
                    }
                    GridRow {
                        ReportValue(title: strings.overwritten, value: strings.sectors(report.stats.overwrittenSectors))
                        ReportValue(
                            title: strings.slightlyChanged,
                            value: strings.sectors(report.stats.slightlyChangedSectors)
                        )
                        ReportValue(title: strings.corrupted, value: strings.sectors(report.stats.corruptedSectors))
                    }
                    GridRow {
                        ReportValue(title: strings.writeTime, value: ByteCountFormat.duration(report.writeDuration))
                        ReportValue(title: strings.verifyTime, value: ByteCountFormat.duration(report.verifyDuration))
                        ReportValue(title: strings.files, value: "\(report.generatedFileCount)")
                    }
                }

                if let firstError = report.stats.firstError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(strings.firstError)
                            .font(.headline)
                        Text("\(strings.offset) \(hex(firstError.offset))")
                        Text("\(strings.expected) \(hex(firstError.expectedWord))")
                        Text("\(strings.found) \(hex(firstError.foundWord))")
                    }
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.log)
                        .font(.headline)

                    if logEntries.isEmpty {
                        Text(strings.noLogEntries)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logEntries) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(entry.date, style: .time)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 76, alignment: .leading)
                                Text(entry.message)
                                    .textSelection(.enabled)
                            }
                            .font(.callout)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var verdictIcon: String {
        switch report.verdict {
        case .notRun: "circle"
        case .passed: "checkmark.seal"
        case .failed: "xmark.octagon"
        case .cancelled: "stop.circle"
        }
    }

    private var verdictColor: Color {
        switch report.verdict {
        case .notRun: .secondary
        case .passed: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }

    private func hex(_ value: UInt64) -> String {
        "0x" + String(value, radix: 16, uppercase: false)
    }
}

private struct ReportValue: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
