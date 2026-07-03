import SwiftUI

struct ContentView: View {
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.defaultLanguage.rawValue
    @StateObject private var controller = TestController()

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .en
    }

    private var strings: AppStrings {
        language.strings
    }

    var body: some View {
        HSplitView {
            TargetPanelView(controller: controller, strings: strings)
                .frame(minWidth: 310, idealWidth: 340, maxWidth: 380)

            VStack(spacing: 0) {
                ProgressPanelView(controller: controller, strings: strings)

                Divider()

                ReportPanelView(report: controller.report, logEntries: controller.logEntries, strings: strings)
            }
            .frame(minWidth: 520)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolbarActivityNoticeView(controller: controller, strings: strings)
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            languageRawValue = option.rawValue
                        } label: {
                            if option == language {
                                Label(option.displayName, systemImage: "checkmark")
                            } else {
                                Text(option.displayName)
                            }
                        }
                }
                } label: {
                    Image(systemName: "globe")
                        .frame(width: 24)
                }
                .menuStyle(.button)
                .controlSize(.regular)
                .help(strings.languagePickerHelp)
                .accessibilityLabel(strings.languagePickerLabel)
                .accessibilityValue(language.displayName)
            }
        }
        .onAppear {
            controller.language = language
        }
        .onChange(of: language) { _, newValue in
            controller.language = newValue
        }
        .focusedSceneValue(\.trueByteCommandActions, TrueByteCommandActions(
            strings: strings,
            selectTarget: controller.selectTarget,
            start: controller.startWriteVerify,
            verifyOnly: controller.startVerifyOnly,
            stop: controller.cancel
        ))
    }
}

private struct ToolbarActivityNoticeView: View {
    @ObservedObject var controller: TestController
    var strings: AppStrings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if let notice = activityNotice(now: timeline.date) {
                Label {
                    Text(notice.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } icon: {
                    Image(systemName: notice.systemImage)
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(notice.color)
                .frame(maxWidth: 640)
                .help(notice.text)
                .accessibilityLabel(notice.text)
            }
        }
    }

    private func activityNotice(now: Date) -> ToolbarActivityNotice? {
        if controller.isCancelling {
            return ToolbarActivityNotice(
                text: strings.cancelling,
                systemImage: "hourglass",
                color: .secondary
            )
        }

        guard isActive else { return nil }
        let quietSeconds = now.timeIntervalSince(controller.progress.lastActivityAt)

        if controller.progress.isSyncing {
            let text = quietSeconds > 8
                ? strings.flushingTakingLonger
                : strings.flushingFileData
            return ToolbarActivityNotice(
                text: text,
                systemImage: "externaldrive.badge.timemachine",
                color: .secondary
            )
        }

        if quietSeconds > 15 {
            return ToolbarActivityNotice(
                text: strings.noByteProgress(seconds: Int(quietSeconds)),
                systemImage: "exclamationmark.triangle",
                color: .orange
            )
        }

        return nil
    }

    private var isActive: Bool {
        switch controller.progress.phase {
        case .writing, .verifying: true
        default: false
        }
    }
}

private struct ToolbarActivityNotice {
    var text: String
    var systemImage: String
    var color: Color
}

#Preview {
    ContentView()
}
