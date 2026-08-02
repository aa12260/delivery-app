import SwiftUI

@main
struct DeliveryManagerApp: App {
    @StateObject private var store = DeliveryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
