import SpriteKit

/// Scene displayed after the player loses all lives, showing score and high score.
class GameOverScene: SKScene {

    var finalScore: Int = 0

    /// Saves the high score if beaten and builds the game over UI with score and replay prompt.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)

        // Save high score
        let previousBest = UserDefaults.standard.integer(forKey: "CowsInTheDitchHighScore")
        let isNewHighScore = finalScore > previousBest
        if isNewHighScore {
            UserDefaults.standard.set(finalScore, forKey: "CowsInTheDitchHighScore")
        }
        let highScore = max(finalScore, previousBest)

        // Game Over title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Game Over"
        title.fontSize = 40
        title.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(title)

        // Sad cow
        let sadCow = SKLabelNode(text: "\u{1F404}")
        sadCow.fontSize = 60
        sadCow.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        addChild(sadCow)

        // Score
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreLabel.text = "Cows Saved: \(finalScore)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
        addChild(scoreLabel)

        // High score / new record
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if isNewHighScore && finalScore > 0 {
            highScoreLabel.text = "New High Score!"
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)

            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4)
            ]))
            highScoreLabel.run(pulse)
        } else {
            highScoreLabel.text = "Best: \(highScore)"
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.8)
        }
        highScoreLabel.fontSize = 20
        highScoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.33)
        addChild(highScoreLabel)

        // Message based on performance
        let message = SKLabelNode(fontNamed: "AvenirNext-Regular")
        if finalScore == 0 {
            message.text = "The cows need you!"
        } else if finalScore < 10 {
            message.text = "Good effort, farmer!"
        } else if finalScore < 25 {
            message.text = "Great herding!"
        } else {
            message.text = "Master Farmer!"
        }
        message.fontSize = 18
        message.fontColor = SKColor(white: 1.0, alpha: 0.7)
        message.position = CGPoint(x: size.width / 2, y: size.height * 0.27)
        addChild(message)

        // Tap to play again
        let playAgain = SKLabelNode(fontNamed: "AvenirNext-Medium")
        playAgain.text = "Tap to Play Again"
        playAgain.fontSize = 22
        playAgain.fontColor = SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        playAgain.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        addChild(playAgain)

        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        playAgain.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }

    /// Transitions to a new GameScene when the player taps to replay.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
