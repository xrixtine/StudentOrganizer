import UIKit

/// Owns the app's window. Main.storyboard (set in Info.plist) creates the window and
/// its navigation controller automatically, so this class only adds styling and saving.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Tinting the window gives every bar button, date picker and checkmark the brand accent.
        window?.tintColor = Theme.accent
    }

    // Save when the app goes to the background, because iOS may close it
    // later without calling applicationWillTerminate.
    func sceneDidEnterBackground(_ scene: UIScene) {
        CoreDataStack.shared.save()
    }
}
