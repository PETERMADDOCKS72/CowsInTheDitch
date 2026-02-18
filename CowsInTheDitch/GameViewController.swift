import UIKit
import SpriteKit

/// View controller that hosts the SpriteKit view and presents the initial menu scene.
class GameViewController: UIViewController {

    private var hasPresented = false

    /// Presents the MenuScene once the view has its final layout dimensions.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasPresented, let skView = view as? SKView else { return }
        hasPresented = true

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
    }

    /// Restricts the game to portrait orientation only.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    /// Hides the status bar for a full-screen game experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Creates an SKView as the root view for SpriteKit rendering.
    override func loadView() {
        self.view = SKView()
    }
}
