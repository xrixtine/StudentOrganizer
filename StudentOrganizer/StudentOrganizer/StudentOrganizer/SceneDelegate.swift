import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    
    var window: UIWindow?

    func sceneDidEnterBackground(_ scene: UIScene) {
        CoreDataStack.shared.save()
    }
}
