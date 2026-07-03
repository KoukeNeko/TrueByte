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

#Preview {
    ContentView()
}
