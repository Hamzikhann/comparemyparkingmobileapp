import UIKit
import Flutter
import FirebaseCore
import Stripe

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase first
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Configure Stripe
        StripeAPI.defaultPublishableKey = "pk_live_51RW4T2GrYrmFa4AwNLWGiNdEP3wHHW5F095Jj6ygcdGQvkYtdDEZsCuUkt3fQXmF1PGWFTUAcOk1CtXO2eatrVvv00YLI6tuLG"
        
        // Register plugins
        GeneratedPluginRegistrant.register(with: self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle Stripe URLs
        if url.scheme?.lowercased() == "parkingpilot" {
            StripeAPI.handleURLCallback(with: url)
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
    
    // For iOS 13+ scene support
    @available(iOS 13.0, *)
    override func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}