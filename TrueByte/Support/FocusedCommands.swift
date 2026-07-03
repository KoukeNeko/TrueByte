import SwiftUI

struct TrueByteCommandActions {
    var strings: AppStrings
    var selectTarget: () -> Void
    var start: () -> Void
    var verifyOnly: () -> Void
    var stop: () -> Void
}

private struct TrueByteCommandActionsKey: FocusedValueKey {
    typealias Value = TrueByteCommandActions
}

extension FocusedValues {
    var trueByteCommandActions: TrueByteCommandActions? {
        get { self[TrueByteCommandActionsKey.self] }
        set { self[TrueByteCommandActionsKey.self] = newValue }
    }
}

struct TrueByteCommandMenu: Commands {
    @FocusedValue(\.trueByteCommandActions) private var actions

    private var strings: AppStrings {
        actions?.strings ?? AppLanguage.defaultLanguage.strings
    }

    var body: some Commands {
        CommandMenu(strings.testMenuTitle) {
            Button(strings.selectTarget) {
                actions?.selectTarget()
            }
            .keyboardShortcut("o")
            .disabled(actions == nil)

            Button(strings.writeVerify) {
                actions?.start()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(actions == nil)

            Button(strings.verifyOnly) {
                actions?.verifyOnly()
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(actions == nil)

            Divider()

            Button(strings.stop) {
                actions?.stop()
            }
            .keyboardShortcut(".", modifiers: [.command])
            .disabled(actions == nil)
        }
    }
}
