import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = "ca-app-pub-9404799280370656/5183307914"
        banner.rootViewController = controller
        banner.load(Request())

        controller.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor)
        ])

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
