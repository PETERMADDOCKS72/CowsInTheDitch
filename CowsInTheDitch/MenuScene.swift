import SpriteKit

/// Title screen scene with sprite-based visuals, animated cow, and play button.
class MenuScene: SKScene {

    /// Builds and positions all menu UI elements centered on the screen.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 1.0)

        let cx = size.width / 2
        let cy = size.height / 2
        let loader = SpriteLoader.shared

        // Tiled grass background (bottom half)
        setupGrassBackground()

        // Drifting clouds
        setupClouds()

        // Title logo sprite
        let logo = loader.titleLogo()
        logo.size = CGSize(width: 300, height: 80)
        logo.position = CGPoint(x: cx, y: cy + 140)
        logo.zPosition = 5
        addChild(logo)

        // Bounce-in animation for logo
        logo.setScale(0.0)
        logo.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        // Animated cow walking across screen
        let cow = loader.cowSprite()
        cow.position = CGPoint(x: -40, y: cy + 30)
        cow.zPosition = 4
        cow.setScale(1.0)
        addChild(cow)

        let walkAcross = SKAction.sequence([
            SKAction.moveTo(x: size.width + 40, duration: 6.0),
            SKAction.moveTo(x: -40, duration: 0),
        ])
        cow.run(SKAction.repeatForever(walkAcross))

        // Gentle bob while walking
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.3),
            SKAction.moveBy(x: 0, y: -3, duration: 0.3),
        ])
        cow.run(SKAction.repeatForever(bob))

        // High score on wooden sign
        let highScore = UserDefaults.standard.integer(forKey: "CowsInTheDitchHighScore")
        if highScore > 0 {
            let badge = loader.scoreBadge()
            badge.size = CGSize(width: 180, height: 44)
            badge.position = CGPoint(x: cx, y: cy - 30)
            badge.zPosition = 5
            addChild(badge)

            let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            highScoreLabel.text = "Best: \(highScore)"
            highScoreLabel.fontSize = 20
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
            highScoreLabel.horizontalAlignmentMode = .center
            highScoreLabel.verticalAlignmentMode = .center
            highScoreLabel.position = CGPoint(x: cx, y: cy - 30)
            highScoreLabel.zPosition = 6
            addChild(highScoreLabel)
        }

        // Play button sprite
        let playBtn = loader.playButton()
        playBtn.size = CGSize(width: 200, height: 60)
        playBtn.position = CGPoint(x: cx, y: cy - 100)
        playBtn.zPosition = 5
        addChild(playBtn)

        // Gentle pulse on play button
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8),
        ]))
        playBtn.run(pulse)

        // Instructions
        let instructions = SKLabelNode(fontNamed: "AvenirNext-Regular")
        instructions.text = "Drag the farmer to herd your cows!"
        instructions.fontSize = 16
        instructions.fontColor = SKColor(white: 1.0, alpha: 0.8)
        instructions.position = CGPoint(x: cx, y: cy - 155)
        instructions.zPosition = 5
        addChild(instructions)

        // Version number
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let versionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        versionLabel.text = "v\(version)"
        versionLabel.fontSize = 14
        versionLabel.fontColor = SKColor(white: 1.0, alpha: 0.4)
        versionLabel.position = CGPoint(x: cx, y: 20)
        versionLabel.zPosition = 5
        addChild(versionLabel)
    }

    /// Creates tiled grass background for the bottom portion of the menu.
    private func setupGrassBackground() {
        let loader = SpriteLoader.shared
        let tileSize: CGFloat = 170
        let grassHeight = size.height * 0.45

        let cols = Int(ceil(size.width / tileSize)) + 1
        let rows = Int(ceil(grassHeight / tileSize)) + 1

        for col in 0..<cols {
            for row in 0..<rows {
                let tile = loader.backgroundGrassTile()
                tile.anchorPoint = .zero
                tile.size = CGSize(width: tileSize, height: tileSize)
                tile.position = CGPoint(x: CGFloat(col) * tileSize,
                                        y: CGFloat(row) * tileSize)
                tile.zPosition = -1
                addChild(tile)
            }
        }
    }

    /// Adds drifting cloud sprites.
    private func setupClouds() {
        let loader = SpriteLoader.shared
        for i in 1...3 {
            let cloud = loader.cloudSprite(variant: i)
            cloud.size = CGSize(width: 80, height: 40)
            let startX = CGFloat.random(in: 0...size.width)
            let y = size.height - CGFloat.random(in: 40...120)
            cloud.position = CGPoint(x: startX, y: y)
            cloud.zPosition = 0
            cloud.alpha = 0.5
            addChild(cloud)

            let speed = CGFloat.random(in: 12...25)
            let duration = TimeInterval((size.width + 100) / speed)
            let drift = SKAction.sequence([
                SKAction.moveTo(x: size.width + 50, duration: duration),
                SKAction.moveTo(x: -50, duration: 0),
            ])
            cloud.run(SKAction.repeatForever(drift))
        }
    }

    /// Transitions to the GameScene when the player taps the play button.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if play button was tapped
        let tappedNodes = nodes(at: location)
        let tappedButton = tappedNodes.contains { $0.name == "playButton" }

        if tappedButton {
            // Button press animation then transition
            if let btn = childNode(withName: "playButton") {
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
