import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "MapsApiKey") as? String GMSServices.provideAPIKey(apiKey ?? "")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
