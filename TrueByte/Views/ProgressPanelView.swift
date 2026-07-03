import SwiftUI

struct ProgressPanelView: View {
    @ObservedObject var controller: TestController
    var strings: AppStrings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            content(now: timeline.date)
        }
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.title(for: controller.progress.phase))
                        .font(.title.weight(.semibold))
                    Text(controller.progress.localizedStatusLine(strings: strings))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(percentText)
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .monospacedDigit()
            }

            ProgressView(value: controller.progress.fractionCompleted)
                .progressViewStyle(.linear)

            HStack(spacing: 12) {
                MetricView(title: strings.written, value: ByteCountFormat.fileSize(controller.progress.writtenBytes))
                MetricView(title: strings.verified, value: ByteCountFormat.fileSize(controller.progress.verifiedBytes))
                MetricView(title: strings.write, value: ByteCountFormat.speed(controller.progress.writeSpeedBytesPerSecond))
                MetricView(title: strings.read, value: ByteCountFormat.speed(controller.progress.readSpeedBytesPerSecond))
            }

            HStack(spacing: 12) {
                MetricView(title: strings.elapsed, value: elapsedText(now: now))
                MetricView(title: strings.remaining, value: remainingText)
            }

            if hasCurrentFile {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(fileTitle, systemImage: "doc")
                            .lineLimit(1)
                        Spacer()
                        Text(filePercentText)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.callout)

                    ProgressView(value: controller.progress.fileFractionCompleted)
                        .progressViewStyle(.linear)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }

    private var percentText: String {
        let value = controller.progress.fractionCompleted * 100
        return value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }

    private var hasCurrentFile: Bool {
        !controller.progress.currentFileName.isEmpty && controller.progress.totalFiles > 0
    }

    private var fileTitle: String {
        strings.fileTitle(
            index: controller.progress.currentFileIndex,
            total: controller.progress.totalFiles,
            name: controller.progress.currentFileName
        )
    }

    private var filePercentText: String {
        let value = controller.progress.fileFractionCompleted * 100
        return value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }

    private func elapsedText(now: Date) -> String {
        guard let startedAt = controller.progress.startedAt else { return "0s" }
        return ByteCountFormat.duration(now.timeIntervalSince(startedAt))
    }

    private var remainingText: String {
        guard isActive else { return "0s" }
        let remainingBytes = controller.progress.totalBytes > controller.progress.activeBytes
            ? controller.progress.totalBytes - controller.progress.activeBytes
            : 0
        let speed = controller.progress.activeSpeedBytesPerSecond
        guard remainingBytes > 0, speed > 0 else { return strings.estimating }
        return ByteCountFormat.duration(Double(remainingBytes) / speed)
    }

    private var isActive: Bool {
        switch controller.progress.phase {
        case .writing, .verifying: true
        default: false
        }
    }

}

private struct MetricView: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
