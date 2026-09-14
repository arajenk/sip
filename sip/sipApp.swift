import SwiftUI

@main
struct sipApp: App {
    var body: some Scene {
        MenuBarExtra("Sip", systemImage: "drop.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
