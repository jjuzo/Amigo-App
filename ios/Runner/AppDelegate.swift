import UIKit
import Flutter
import GoogleMpas

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSService.provideAPIKEY("AIzaSyDWe7flYWZScWDhm3zvfucIHhs_XGS7Ibk")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
