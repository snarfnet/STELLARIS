import SwiftUI
import GoogleMobileAds

@main
struct STELLARISApp: App {
    init() {
        MobileAds.shared.start { _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
