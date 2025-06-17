import Flutter
import UIKit
import Stripe

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    StripeAPI.defaultPublishableKey = "pk_live_51RW4T2GrYrmFa4AwNLWGiNdEP3wHHW5F095Jj6ygcdGQvkYtdDEZsCuUkt3fQXmF1PGWFTUAcOk1CtXO2eatrVvv00YLI6tuLG"
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
