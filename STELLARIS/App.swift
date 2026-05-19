import SwiftUI
import GoogleMobileAds

class STELLARISAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            DispatchQueue.main.async {
                MobileAds.shared.start()
            }
        }
        return true
    }
}

@main
struct STELLARISApp: App {
    @UIApplicationDelegateAdaptor(STELLARISAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
