import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct STELLARISApp: App {
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    guard !attRequested else { return }
                    attRequested = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ATTrackingManager.requestTrackingAuthorization { _ in
                            DispatchQueue.main.async {
                                MobileAds.shared.start()
                            }
                        }
                    }
                }
        }
    }
}
