import UIKit

/// Main application delegate that bootstraps the game window.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Creates the main window and sets the GameViewController as root.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
