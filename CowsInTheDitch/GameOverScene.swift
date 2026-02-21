import SpriteKit

/// Scene displayed after the player loses all lives, showing score and high score with sprite visuals.
class GameOverScene: SKScene {

    var finalScore: Int = 0

    /// Saves the high score if beaten and builds the game over UI with sprites and animations.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)

        let cx = size.width / 2
        let loader = SpriteLoader.shared

        // Save high score
        let previousBest = UserDefaults.standard.integer(forKey: "CowsInTheDitchHighScore")
        let isNewHighScore = finalScore > previousBest
        if isNewHighScore {
            UserDefaults.standard.set(finalScore, forKey: "CowsInTheDitchHighScore")
        }
        let highScore = max(finalScore, previousBest)

        // Dark gradient overlay (subtle vignette effect via semi-transparent nodes)
        let topOverlay = SKSpriteNode(color: SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.3),
                                       size: CGSize(width: size.width, height: size.height / 2))
        topOverlay.anchorPoint = .zero
        topOverlay.position = CGPoint(x: 0, y: size.height / 2)
        topOverlay.zPosition = -1
        addChild(topOverlay)

        // Game Over banner sprite (slides in with bounce)
        let banner = loader.gameOverBanner()
        banner.size = CGSize(width: 300, height: 80)
        banner.position = CGPoint(x: cx, y: size.height + 60)
        banner.zPosition = 5
        addChild(banner)

        let slideIn = SKAction.moveTo(y: size.height * 0.68, duration: 0.6)
        slideIn.timingMode = .easeOut
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.15),
            SKAction.moveBy(x: 0, y: -15, duration: 0.15),
        ])
        banner.run(SKAction.sequence([slideIn, bounce]))

        // Drowning cow sprite
        let sadCow = SKSpriteNode(texture: loader.texture("cow_drowning"))
        sadCow.setScale(0.8)
        sadCow.position = CGPoint(x: cx, y: size.height * 0.52)
        sadCow.zPosition = 5
        sadCow.alpha = 0
        addChild(sadCow)

        sadCow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.3),
        ]))

        // Score badge background
        let scoreBg = loader.scoreBadge()
        scoreBg.size = CGSize(width: 240, height: 60)
        scoreBg.position = CGPoint(x: cx, y: size.height * 0.38)
        scoreBg.zPosition = 5
        scoreBg.alpha = 0
        addChild(scoreBg)

        scoreBg.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeIn(withDuration: 0.3),
        ]))

        // Score count-up animation
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Cows Saved: 0"
        scoreLabel.fontSize = 26
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: cx, y: size.height * 0.38)
        scoreLabel.zPosition = 6
        scoreLabel.alpha = 0
        addChild(scoreLabel)

        scoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeIn(withDuration: 0.3),
        ]))

        // Count up the score
        if finalScore > 0 {
            let countSteps = min(finalScore, 30)
            let stepDuration = 1.0 / Double(countSteps)
            var countActions: [SKAction] = [SKAction.wait(forDuration: 1.2)]
            for i in 1...countSteps {
                let displayScore = Int(Double(finalScore) * Double(i) / Double(countSteps))
                countActions.append(SKAction.run { scoreLabel.text = "Cows Saved: \(displayScore)" })
                countActions.append(SKAction.wait(forDuration: stepDuration))
            }
            scoreLabel.run(SKAction.sequence(countActions))
        }

        // High score / new record
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if isNewHighScore && finalScore > 0 {
            highScoreLabel.text = "New High Score!"
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)

            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4)
            ]))
            highScoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5),
                SKAction.run { highScoreLabel.alpha = 1.0 },
                pulse
            ]))
            highScoreLabel.alpha = 0

            // Golden particle burst for new high score
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.addChild(ParticleEffects.goldenBurst(at: CGPoint(x: cx, y: self.size.height * 0.33)))
                }
            ]))
        } else {
            highScoreLabel.text = "Best: \(highScore)"
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.8)
            highScoreLabel.alpha = 0
            highScoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeIn(withDuration: 0.3)
            ]))
        }
        highScoreLabel.fontSize = 20
        highScoreLabel.position = CGPoint(x: cx, y: size.height * 0.31)
        highScoreLabel.zPosition = 6
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
        message.position = CGPoint(x: cx, y: size.height * 0.25)
        message.zPosition = 5
        message.alpha = 0
        addChild(message)

        message.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Replay button sprite
        let replayBtn = loader.replayButton()
        replayBtn.size = CGSize(width: 220, height: 65)
        replayBtn.position = CGPoint(x: cx, y: size.height * 0.15)
        replayBtn.zPosition = 5
        replayBtn.alpha = 0
        addChild(replayBtn)

        replayBtn.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8),
            ]))
        ]))
    }

    /// Transitions to a new GameScene when the player taps the replay button.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let tappedNodes = nodes(at: location)
        let tappedButton = tappedNodes.contains { $0.name == "replayButton" }

        if tappedButton {
            if let btn = childNode(withName: "replayButton") {
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1),
                    SKAction.run { [weak self] in
                        guard let self = self else { return }
                        let gameScene = GameScene(size: self.size)
                        gameScene.scaleMode = .resizeFill
                        let transition = SKTransition.fade(withDuration: 0.5)
                        self.view?.presentScene(gameScene, transition: transition)
                    }
                ]))
            }
        }
    }
}
