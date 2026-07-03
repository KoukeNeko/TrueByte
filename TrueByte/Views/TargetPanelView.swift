import SwiftUI

struct TargetPanelView: View {
    @ObservedObject var controller: TestController
    var strings: AppStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TrueByte")
                    .font(.largeTitle.weight(.semibold))

                Text(strings.appSubtitle)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(strings.target, systemImage: "externaldrive")
                        .font(.headline)
                    Spacer()
                    Button {
                        controller.selectTarget()
                    } label: {
                        Label(controller.targetInfo == nil ? strings.selectTarget : strings.change, systemImage: "folder")
                    }
                    .help(controller.targetInfo == nil ? strings.selectTarget : strings.changeTarget)
                    .disabled(controller.isBusy)
                }

                Group {
                    if let target = controller.targetInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(target.displayName)
                                .font(.title3.weight(.medium))
                                .lineLimit(1)

                            Text(target.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .textSelection(.enabled)

                            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                                GridRow {
                                    Text(strings.available)
                                        .foregroundStyle(.secondary)
                                    Text(ByteCountFormat.fileSize(target.availableBytes))
                                }
                                GridRow {
                                    Text(strings.total)
                                        .foregroundStyle(.secondary)
                                    Text(ByteCountFormat.fileSize(target.totalBytes))
                                }
                                GridRow {
                                    Text(".h2w")
                                        .foregroundStyle(.secondary)
                                    Text(strings.h2wFileSummary(
                                        count: target.h2wFileCount,
                                        size: ByteCountFormat.fileSize(target.h2wBytes)
                                    ))
                                }
                            }
                            .font(.callout)
                        }
                    } else {
                        Color.clear
                            .accessibilityHidden(true)
                    }
                }
                .frame(height: 138, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(strings.mode)
                    .font(.headline)

                Picker(strings.mode, selection: $controller.mode) {
                    ForEach(TestMode.allCases) { mode in
                        Text(strings.title(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(controller.isBusy)

                Toggle(strings.useAllAvailableSpace, isOn: $controller.useAllAvailableSpace)
                    .disabled(controller.isBusy || controller.mode == .verifyOnly)

                HStack {
                    Text(strings.size)
                    Spacer()
                    TextField("GiB", value: $controller.customSizeGiB, format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 76)
                    Stepper("", value: $controller.customSizeGiB, in: 0.001...8192, step: 1)
                        .labelsHidden()
                    Text("GiB")
                        .foregroundStyle(.secondary)
                }
                .disabled(controller.useAllAvailableSpace || controller.isBusy || controller.mode == .verifyOnly)

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                    GridRow {
                        Text(strings.planned)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormat.fileSize(controller.plannedTestBytes))
                    }

                    if controller.plannedReserveBytes > 0 {
                        GridRow {
                            Text(strings.reserved)
                                .foregroundStyle(.secondary)
                            Text(ByteCountFormat.fileSize(controller.plannedReserveBytes))
                        }
                    }
                }
                .font(.caption)
            }

            Spacer()

            if let errorMessage = controller.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button(role: .destructive) {
                    controller.clearTestFiles()
                } label: {
                    Label(strings.clearH2W, systemImage: "trash")
                }
                .disabled(!controller.canClearTestFiles)

                Spacer()

                if controller.isRunning {
                    Button(role: .cancel) {
                        controller.cancel()
                    } label: {
                        Label(
                            controller.isCancelling ? strings.cancelling : strings.stop,
                            systemImage: controller.isCancelling ? "hourglass" : "stop.fill"
                        )
                    }
                    .keyboardShortcut(".", modifiers: [.command])
                    .controlSize(.large)
                    .disabled(!controller.canCancel)
                } else {
                    Button {
                        controller.start()
                    } label: {
                        Label(controller.mode == .verifyOnly ? strings.verify : strings.start, systemImage: "play.fill")
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .controlSize(.large)
                    .disabled(!controller.canStart)
                }
            }
        }
        .padding(24)
    }
}
