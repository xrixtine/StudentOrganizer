import UIKit

/// App entry point. Prepares the shared services before the first screen is shown;
/// the window and the screens themselves come from Main.storyboard via SceneDelegate.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Load the database early so the first screen can fetch immediately.
        _ = CoreDataStack.shared
        // Appearance proxies only affect controls created afterwards, so apply them before any UI loads.
        Theme.applyGlobalAppearance()
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.save()
    }
}
