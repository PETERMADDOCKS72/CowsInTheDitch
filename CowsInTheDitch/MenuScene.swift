import SpriteKit

/// Title screen scene displaying the game name, high score, and tap-to-play prompt.
class MenuScene: SKScene {

    /// Builds and positions all menu UI elements centered on the screen.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0)

        let cx = size.width / 2
        let cy = size.height / 2

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Cows in the Ditch"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: cx, y: cy + 100)
        addChild(title)

        // Cow emoji decoration
        let cowEmoji = SKLabelNode(text: "\u{1F404}")
        cowEmoji.fontSize = 80
        cowEmoji.position = CGPoint(x: cx, y: cy + 10)
        addChild(cowEmoji)

        // High score
        let highScore = UserDefaults.standard.integer(forKey: "CowsInTheDitchHighScore")
        if highScore > 0 {
            let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            highScoreLabel.text = "Best: \(highScore)"
            highScoreLabel.fontSize = 22
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
            highScoreLabel.position = CGPoint(x: cx, y: cy - 50)
            addChild(highScoreLabel)
        }

        // Tap to play
        let playLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        playLabel.text = "Tap to Play"
        playLabel.fontSize = 24
        playLabel.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0)
        playLabel.position = CGPoint(x: cx, y: cy - 110)
        addChild(playLabel)

        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        playLabel.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))

        // Instructions
        let instructions = SKLabelNode(fontNamed: "AvenirNext-Regular")
        instructions.text = "Drag the farmer to herd your cows!"
        instructions.fontSize = 16
        instructions.fontColor = SKColor(white: 1.0, alpha: 0.7)
        instructions.position = CGPoint(x: cx, y: cy - 155)
        addChild(instructions)
    }

    /// Transitions to the GameScene when the player taps anywhere.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
