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

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            language
        } set: { newValue in
            languageRawValue = newValue.rawValue
        }
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
                Picker(strings.languagePickerLabel, selection: languageSelection) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.toolbarTitle)
                            .tag(language)
                            .help(language.displayName)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 156)
                .help(strings.languagePickerHelp)
                .accessibilityLabel(strings.languagePickerLabel)
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
