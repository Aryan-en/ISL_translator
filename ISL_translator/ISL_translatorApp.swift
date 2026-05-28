import SwiftUI

@main
struct ISL_translatorApp: App {

    var body: some Scene {
        WindowGroup("ISL Translator") {
            ContentView()
                .frame(minWidth: 1050, idealWidth: 1280,
                       minHeight: 680,  idealHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Translation") {
                Button("Clear Sentence") {}
                    .keyboardShortcut("k", modifiers: [.command])
                Button("Speak Sentence") {}
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
