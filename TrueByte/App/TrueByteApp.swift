import SwiftUI

@main
struct TrueByteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1320, height: 860)
        .commands {
            TrueByteCommandMenu()
        }
    }
}
