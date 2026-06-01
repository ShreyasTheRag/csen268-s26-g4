import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    let mapsChannel = FlutterMethodChannel(name: "com.example.app/google_maps", binaryMessenger: controller.binaryMessenger)
    mapsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "initializeMaps" {
        if let args = call.arguments as? Dictionary<String, Any>,
           let apiKey = args["apiKey"] as? String {
            GMSServices.provideAPIKey(apiKey)
            result(true)
        } else {
            result(FlutterError(code: "INVALID_ARGS", message: "API Key is missing or invalid", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}