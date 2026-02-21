import SpriteKit

/// Main gameplay scene where the player herds cows away from a ditch and through a gated fence.
class GameScene: SKScene {

    // MARK: - Game constants

    private let ditchHeight: CGFloat = 80
    private let fenceThickness: CGFloat = 8
    private let farmerRadius: CGFloat = 25
    private let cowRadius: CGFloat = 20
    private let herdingRadius: CGFloat = 70
    private let herdingForce: CGFloat = 3.0
    private let lassoRange: CGFloat = 100
    private let initialDrowningDuration: TimeInterval = 10.0
    private let minimumDrowningDuration: TimeInterval = 1.0
    private let initialSpawnInterval: TimeInterval = 2.5
    private let minimumSpawnInterval: TimeInterval = 0.8
    private let initialCowSpeed: CGFloat = 40
    private let difficultyInterval: TimeInterval = 30.0

    // Gate constants
    private let gateFullWidth: CGFloat = 160
    private let gateOpenDuration: TimeInterval = 2.5
    private let gateCloseDuration: TimeInterval = 2.5
    private let gateStayOpenDuration: TimeInterval = 3.0
    private let gateStayClosedDuration: TimeInterval = 3.0

    // MARK: - Fence & gate layout

    /// Y position of the fence barrier across the screen.
    private var fenceY: CGFloat { return size.height * 0.68 }

    /// X center of the gate opening in the fence.
    private var gateCenterX: CGFloat { return size.width / 2 }

    // MARK: - Game state

    private var farmer: SKSpriteNode!
    private var isDraggingFarmer = false
    private var dragOffset = CGPoint.zero
    private var score = 0
    private var lives = 3
    private var gameOver = false
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var timeSinceLastSpawn: TimeInterval = 0
    private var difficultyLevel = 0

    // Gate state
    private enum GateState { case opening, open, closing, closed }
    private var gateState: GateState = .closed
    private var gateTimer: TimeInterval = 1.0
    private var gateOpenAmount: CGFloat = 0.0
    private var leftDoor: SKSpriteNode!
    private var rightDoor: SKSpriteNode!
    private var gateIndicator: SKSpriteNode!

    // Dust effect throttle
    private var lastDustTime: TimeInterval = 0

    // Giddy-up sound throttle
    private var lastGiddyUpTime: TimeInterval = 0

    // MARK: - HUD

    private var scoreLabel: SKLabelNode!
    private var scoreBadge: SKSpriteNode!
    private var livesDisplay: SKNode!

    // MARK: - Computed difficulty

    /// Time between cow spawns, decreasing as difficulty rises.
    private var currentSpawnInterval: TimeInterval {
        return max(minimumSpawnInterval, initialSpawnInterval - Double(difficultyLevel) * 0.3)
    }

    /// Cow downward drift speed, increasing as difficulty rises.
    private var currentCowSpeed: CGFloat {
        return initialCowSpeed + CGFloat(difficultyLevel) * 8
    }

    /// Seconds a cow survives in the ditch before drowning, decreasing with difficulty.
    private var currentDrowningDuration: TimeInterval {
        return max(minimumDrowningDuration, initialDrowningDuration - Double(difficultyLevel) * 1.5)
    }

    /// Current width of the gate opening in points based on open amount.
    private var currentGateOpening: CGFloat {
        return gateFullWidth * gateOpenAmount
    }

    // MARK: - Scene setup

    /// Initializes all visual elements and game objects when the scene is presented.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 1.0)
        setupBackground()
        setupDitch()
        setupSafePasture()
        setupFence()
        setupGate()
        setupFarmer()
        setupHUD()
        setupClouds()
    }

    /// Creates tiled grass background for the play field.
    private func setupBackground() {
        let loader = SpriteLoader.shared
        let tileSize: CGFloat = 170  // ~512/3
        let fieldBottom = ditchHeight
        let fieldTop = fenceY

        let cols = Int(ceil(size.width / tileSize)) + 1
        let rows = Int(ceil((fieldTop - fieldBottom) / tileSize)) + 1

        for col in 0..<cols {
            for row in 0..<rows {
                let tile = loader.backgroundGrassTile()
                tile.anchorPoint = .zero
                tile.size = CGSize(width: tileSize, height: tileSize)
                tile.position = CGPoint(x: CGFloat(col) * tileSize,
                                        y: fieldBottom + CGFloat(row) * tileSize)
                tile.zPosition = -1
                addChild(tile)
            }
        }
    }

    /// Creates the water-filled ditch at the bottom of the screen with animated water.
    private func setupDitch() {
        let loader = SpriteLoader.shared

        // Animated water
        let ditchWater = loader.ditchWaterSprite(frame: 1)
        ditchWater.anchorPoint = .zero
        ditchWater.size = CGSize(width: size.width, height: ditchHeight)
        ditchWater.position = .zero
        ditchWater.zPosition = 1
        addChild(ditchWater)

        let waterTextures = loader.ditchWaterTextures()
        let animateWater = SKAction.animate(with: waterTextures, timePerFrame: 0.5)
        ditchWater.run(SKAction.repeatForever(animateWater))

        // Ditch edge
        let edge = loader.ditchEdgeSprite()
        edge.anchorPoint = CGPoint(x: 0, y: 0)
        edge.size = CGSize(width: size.width, height: 8)
        edge.position = CGPoint(x: 0, y: ditchHeight - 4)
        edge.zPosition = 2
        addChild(edge)
    }

    /// Creates the darker green safe pasture area above the fence.
    private func setupSafePasture() {
        let loader = SpriteLoader.shared
        let pastureHeight = size.height - fenceY - fenceThickness
        let tileSize: CGFloat = 170

        let cols = Int(ceil(size.width / tileSize)) + 1
        let rows = Int(ceil(pastureHeight / tileSize)) + 1

        for col in 0..<cols {
            for row in 0..<rows {
                let tile = loader.safePastureTile()
                tile.anchorPoint = .zero
                tile.size = CGSize(width: tileSize, height: tileSize)
                tile.position = CGPoint(x: CGFloat(col) * tileSize,
                                        y: fenceY + fenceThickness + CGFloat(row) * tileSize)
                tile.zPosition = 0
                addChild(tile)
            }
        }

        let safeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        safeLabel.text = "SAFE PASTURE"
        safeLabel.fontSize = 16
        safeLabel.fontColor = SKColor(white: 1.0, alpha: 0.35)
        safeLabel.position = CGPoint(x: size.width / 2, y: fenceY + fenceThickness + pastureHeight / 2)
        safeLabel.zPosition = 1
        addChild(safeLabel)
    }

    /// Draws the fence posts and rails on either side of the gate opening using sprite textures.
    private func setupFence() {
        let y = fenceY
        let postHeight: CGFloat = 40
        let loader = SpriteLoader.shared

        let gateLeftEdge = gateCenterX - gateFullWidth / 2
        let gateRightEdge = gateCenterX + gateFullWidth / 2

        drawFenceSection(from: 0, to: gateLeftEdge, y: y, postHeight: postHeight, loader: loader)
        drawFenceSection(from: gateRightEdge, to: size.width, y: y, postHeight: postHeight, loader: loader)

        // Gate posts (thicker)
        for x in [gateLeftEdge, gateRightEdge] {
            let post = loader.gatePostSprite()
            post.anchorPoint = CGPoint(x: 0.5, y: 0)
            post.size = CGSize(width: 12, height: 48)
            post.position = CGPoint(x: x, y: y - 4)
            post.zPosition = 7
            addChild(post)
        }
    }

    /// Draws a horizontal fence section with evenly spaced posts and rails using sprites.
    private func drawFenceSection(from startX: CGFloat, to endX: CGFloat, y: CGFloat,
                                   postHeight: CGFloat, loader: SpriteLoader) {
        guard endX > startX else { return }

        let spacing: CGFloat = 35
        var x = startX
        while x <= endX {
            let post = loader.fencePostSprite()
            post.anchorPoint = CGPoint(x: 0.5, y: 0)
            post.size = CGSize(width: 8, height: postHeight)
            post.position = CGPoint(x: x, y: y)
            post.zPosition = 6
            addChild(post)
            x += spacing
        }

        for railOffset: CGFloat in [10, 24] {
            let rail = loader.fenceRailSprite()
            rail.anchorPoint = .zero
            rail.size = CGSize(width: endX - startX, height: 6)
            rail.position = CGPoint(x: startX, y: y + railOffset)
            rail.zPosition = 6
            addChild(rail)
        }
    }

    /// Creates the two sliding gate doors and the open/closed indicator using sprites.
    private func setupGate() {
        let y = fenceY
        let loader = SpriteLoader.shared
        let doorWidth = gateFullWidth / 2
        let doorHeight: CGFloat = 36

        leftDoor = loader.gateDoorSprite()
        leftDoor.anchorPoint = CGPoint(x: 0, y: 0)
        leftDoor.size = CGSize(width: doorWidth, height: doorHeight)
        leftDoor.position = CGPoint(x: gateCenterX - gateFullWidth / 2, y: y)
        leftDoor.zPosition = 7
        addChild(leftDoor)

        rightDoor = loader.gateDoorSprite()
        rightDoor.anchorPoint = CGPoint(x: 0, y: 0)
        rightDoor.xScale = -1
        rightDoor.size = CGSize(width: doorWidth, height: doorHeight)
        rightDoor.position = CGPoint(x: gateCenterX + gateFullWidth / 2, y: y)
        rightDoor.zPosition = 7
        addChild(rightDoor)

        gateIndicator = SKSpriteNode(texture: loader.gateIndicatorTexture(open: false))
        gateIndicator.size = CGSize(width: 16, height: 16)
        gateIndicator.position = CGPoint(x: gateCenterX, y: fenceY + 42)
        gateIndicator.zPosition = 8
        addChild(gateIndicator)

        updateGateDoorPositions()
    }

    /// Positions the left and right gate doors based on the current open amount.
    private func updateGateDoorPositions() {
        let halfSlide = (gateFullWidth / 2) * gateOpenAmount
        leftDoor.position.x = gateCenterX - gateFullWidth / 2 - halfSlide
        rightDoor.position.x = gateCenterX + gateFullWidth / 2 + halfSlide

        let cowCanPass = currentGateOpening > cowRadius * 2.2
        gateIndicator.texture = SpriteLoader.shared.gateIndicatorTexture(open: cowCanPass)
    }

    /// Creates the farmer sprite at the center of the play field.
    private func setupFarmer() {
        farmer = SpriteLoader.shared.farmerSprite()
        farmer.position = CGPoint(x: size.width / 2, y: (ditchHeight + fenceY) / 2)
        farmer.zPosition = 5
        addChild(farmer)
    }

    /// Creates the HUD with score badge, score label, and heart-based lives display.
    private func setupHUD() {
        let loader = SpriteLoader.shared

        scoreBadge = loader.scoreBadge()
        scoreBadge.size = CGSize(width: 160, height: 40)
        scoreBadge.position = CGPoint(x: 90, y: size.height - 45)
        scoreBadge.zPosition = 10
        addChild(scoreBadge)

        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Saved: 0"
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 90, y: size.height - 45)
        scoreLabel.zPosition = 11
        addChild(scoreLabel)

        livesDisplay = SKNode()
        livesDisplay.position = CGPoint(x: size.width - 16, y: size.height - 45)
        livesDisplay.zPosition = 10
        addChild(livesDisplay)
        updateLivesDisplay()
    }

    /// Rebuilds the heart sprites in the lives display to reflect the current life count.
    private func updateLivesDisplay() {
        livesDisplay.removeAllChildren()
        let loader = SpriteLoader.shared
        for i in 0..<3 {
            let heart = loader.heartSprite(full: i < lives)
            heart.size = CGSize(width: 28, height: 26)
            heart.position = CGPoint(x: -CGFloat(i) * 32, y: 0)
            livesDisplay.addChild(heart)
        }
    }

    /// Adds drifting cloud sprites across the sky area.
    private func setupClouds() {
        let loader = SpriteLoader.shared
        let skyTop = size.height
        let skyBottom = fenceY + 60

        for i in 1...3 {
            let cloud = loader.cloudSprite(variant: i)
            cloud.size = CGSize(width: 80, height: 40)
            let startX = CGFloat.random(in: -40...(size.width + 40))
            let y = CGFloat.random(in: skyBottom...skyTop - 60)
            cloud.position = CGPoint(x: startX, y: y)
            cloud.zPosition = 0.5
            cloud.alpha = 0.6
            addChild(cloud)

            let speed = CGFloat.random(in: 15...30)
            let duration = TimeInterval((size.width + 120) / speed)
            let drift = SKAction.sequence([
                SKAction.moveTo(x: size.width + 60, duration: duration),
                SKAction.moveTo(x: -60, duration: 0),
            ])
            cloud.run(SKAction.repeatForever(drift))
        }
    }

    // MARK: - Cow spawning

    /// Creates a new cow sprite and adds it to the field just below the fence.
    private func spawnCow() {
        let cow = SpriteLoader.shared.cowSprite()
        let spawnX = CGFloat.random(in: cowRadius * 2...(size.width - cowRadius * 2))
        let spawnY = fenceY - cowRadius - 20
        cow.position = CGPoint(x: spawnX, y: spawnY)
        cow.zPosition = 5

        cow.userData = NSMutableDictionary()
        cow.userData?["velocityX"] = CGFloat.random(in: -15...15)
        cow.userData?["velocityY"] = -currentCowSpeed
        cow.userData?["state"] = "wandering"
        cow.userData?["wanderTimer"] = TimeInterval(0)

        addChild(cow)
    }

    // MARK: - Touch handling

    /// Handles touch start: attempts a lasso rescue first, then checks for farmer drag.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let touch = touches.first else { return }
        let location = touch.location(in: self)

        if tryLassoCow(at: location) {
            return
        }

        let farmerDist = hypot(location.x - farmer.position.x, location.y - farmer.position.y)
        if farmerDist < farmerRadius * 2.5 {
            isDraggingFarmer = true
            dragOffset = CGPoint(x: farmer.position.x - location.x,
                                 y: farmer.position.y - location.y)
            SoundManager.shared.playGiddyUp()
        }
    }

    /// Moves the farmer to follow the player's finger, clamped within the play field.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, isDraggingFarmer, let touch = touches.first else { return }
        let location = touch.location(in: self)

        let newX = max(farmerRadius, min(size.width - farmerRadius, location.x + dragOffset.x))
        let newY = max(ditchHeight + farmerRadius,
                       min(fenceY - farmerRadius, location.y + dragOffset.y))
        farmer.position = CGPoint(x: newX, y: newY)

        // Dust particles (throttled)
        let now = CACurrentMediaTime()
        if now - lastDustTime > 0.3 {
            lastDustTime = now
            addChild(ParticleEffects.dustPuff(at: CGPoint(x: farmer.position.x,
                                                           y: farmer.position.y - farmerRadius)))
        }
    }

    /// Ends the farmer drag when the player lifts their finger.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraggingFarmer = false
    }

    /// Ends the farmer drag if the touch is cancelled by the system.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraggingFarmer = false
    }

    // MARK: - Lasso mechanic

    /// Checks if the player tapped near a drowning cow while the farmer is close to the ditch.
    /// - Returns: `true` if a lasso rescue was triggered.
    private func tryLassoCow(at location: CGPoint) -> Bool {
        let farmerNearDitch = farmer.position.y < ditchHeight + lassoRange
        guard farmerNearDitch else { return false }

        for node in children where node.name == "drowningCow" {
            let dist = hypot(location.x - node.position.x, location.y - node.position.y)
            if dist < cowRadius * 3 {
                performLassoRescue(cow: node)
                return true
            }
        }
        return false
    }

    /// Animates a lasso from the farmer to a drowning cow, pulls it back to the field, and awards bonus points.
    private func performLassoRescue(cow: SKNode) {
        cow.name = "rescuedCow"
        cow.removeAction(forKey: "drowning")

        cow.childNode(withName: "countdownRing")?.removeFromParent()
        cow.childNode(withName: "countdownLabel")?.removeFromParent()
        cow.childNode(withName: "bubbles")?.removeFromParent()

        let lassoLine = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: farmer.position)
        path.addLine(to: cow.position)
        lassoLine.path = path
        lassoLine.strokeColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        lassoLine.lineWidth = 3
        lassoLine.zPosition = 8
        addChild(lassoLine)

        let loop = SKShapeNode(circleOfRadius: 12)
        loop.strokeColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        loop.fillColor = .clear
        loop.lineWidth = 2.5
        loop.position = cow.position
        loop.zPosition = 8
        addChild(loop)

        let fieldMidY = (ditchHeight + fenceY) / 2
        let targetX = CGFloat.random(in: (size.width * 0.2)...(size.width * 0.8))

        let pullAction = SKAction.move(to: CGPoint(x: targetX, y: fieldMidY), duration: 0.6)
        pullAction.timingMode = .easeOut

        cow.run(pullAction) { [weak self] in
            guard let self = self else { return }
            cow.name = "cow"
            cow.userData?["state"] = "wandering"
            cow.userData?["velocityY"] = -self.currentCowSpeed
            cow.userData?["velocityX"] = CGFloat.random(in: -15...15)
            cow.userData?["wanderTimer"] = TimeInterval(0)
            cow.alpha = 1.0
            cow.setScale(0.8)
            // Restore walk texture
            if let sprite = cow as? SKSpriteNode {
                sprite.texture = SpriteLoader.shared.cowWalkTexture()
            }
        }

        let fadeRemove = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        lassoLine.run(fadeRemove)
        loop.run(fadeRemove)

        score += 3
        scoreLabel.text = "Saved: \(score)"

        let bonus = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bonus.text = "+3 RESCUED!"
        bonus.fontSize = 18
        bonus.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        bonus.position = cow.position
        bonus.zPosition = 15
        addChild(bonus)

        let floatUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        bonus.run(SKAction.sequence([
            SKAction.group([floatUp, fade]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Cow enters ditch (drowning state)

    /// Transitions a cow into the drowning state with countdown ring, bobbing, bubbles, and splash.
    private func cowFellInDitch(_ cow: SKNode) {
        cow.name = "drowningCow"
        cow.userData?["state"] = "drowning"
        let duration = currentDrowningDuration
        cow.userData?["drownTimer"] = duration

        cow.position.y = ditchHeight / 2
        cow.zPosition = 3

        // Swap to drowning texture
        if let sprite = cow as? SKSpriteNode {
            sprite.texture = SpriteLoader.shared.cowDrowningTexture()
        }

        // Water splash particles + sound
        addChild(ParticleEffects.waterSplash(at: CGPoint(x: cow.position.x, y: ditchHeight)))
        SoundManager.shared.playSplash()

        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.5)
        let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        cow.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "drowning")

        // Drowning bubbles
        let bubbles = ParticleEffects.drowningBubbles(at: .zero)
        bubbles.name = "bubbles"
        cow.addChild(bubbles)

        let ring = SKShapeNode(circleOfRadius: cowRadius * 1.8)
        ring.strokeColor = .red
        ring.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.15)
        ring.lineWidth = 3
        ring.name = "countdownRing"
        ring.zPosition = 1
        cow.addChild(ring)

        let countLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countLabel.fontSize = 16
        countLabel.fontColor = .white
        countLabel.verticalAlignmentMode = .center
        countLabel.name = "countdownLabel"
        countLabel.position = CGPoint(x: 0, y: cowRadius * 1.8 + 12)
        countLabel.zPosition = 2
        cow.addChild(countLabel)

        let shrink = SKAction.scale(to: 0.1, duration: duration)
        ring.run(shrink)

        let wait = SKAction.wait(forDuration: duration * 0.6)
        let flash = SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        ]))
        cow.run(SKAction.sequence([wait, flash]), withKey: "flash")
    }

    /// Plays the cow sinking animation, decrements a life, and triggers game over if no lives remain.
    private func cowDrowned(_ cow: SKNode) {
        cow.removeAllActions()
        cow.name = "dead"

        let sink = SKAction.group([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.scale(to: 0.3, duration: 0.5),
            SKAction.moveBy(x: 0, y: -20, duration: 0.5)
        ])

        cow.run(SKAction.sequence([sink, SKAction.removeFromParent()]))

        lives -= 1
        updateLivesDisplay()

        // Heart pop animation on the lost heart
        if lives >= 0 && lives < 3 {
            let heartIdx = lives
            if heartIdx < livesDisplay.children.count {
                let lostHeart = livesDisplay.children[heartIdx]
                lostHeart.run(SKAction.sequence([
                    SKAction.scale(to: 1.5, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ]))
            }
        }

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        ])
        run(shake)

        if lives <= 0 {
            triggerGameOver()
        }
    }

    // MARK: - Cow saved

    /// Plays a celebration animation with star particles, increments the score, and removes the cow.
    private func cowReachedSafety(_ cow: SKNode) {
        cow.name = "safe"
        score += 1
        scoreLabel.text = "Saved: \(score)"

        // Celebration star particles
        addChild(ParticleEffects.celebrationStars(at: cow.position))

        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let scaleDown = SKAction.scale(to: 0.0, duration: 0.3)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.45)

        cow.run(SKAction.sequence([
            SKAction.group([scaleUp, SKAction.wait(forDuration: 0.15)]),
            SKAction.group([scaleDown, moveUp]),
            SKAction.removeFromParent()
        ]))

        let plusOne = SKLabelNode(fontNamed: "AvenirNext-Bold")
        plusOne.text = "+1"
        plusOne.fontSize = 20
        plusOne.fontColor = .green
        plusOne.position = cow.position
        plusOne.zPosition = 15
        addChild(plusOne)

        plusOne.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))

        // Score pop animation
        scoreLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
    }

    // MARK: - Game over

    /// Sets the game over flag and transitions to the GameOverScene after a brief delay.
    private func triggerGameOver() {
        gameOver = true

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let gameOverScene = GameOverScene(size: self.size)
                gameOverScene.finalScore = self.score
                gameOverScene.scaleMode = .resizeFill
                let transition = SKTransition.fade(withDuration: 0.8)
                self.view?.presentScene(gameOverScene, transition: transition)
            }
        ]))
    }

    // MARK: - Gate update

    /// Advances the gate state machine (closed -> opening -> open -> closing) and animates the doors.
    private func updateGate(dt: TimeInterval) {
        gateTimer -= dt

        switch gateState {
        case .closed:
            gateOpenAmount = 0
            if gateTimer <= 0 {
                gateState = .opening
                gateTimer = gateOpenDuration
            }

        case .opening:
            gateOpenAmount = CGFloat(1.0 - gateTimer / gateOpenDuration)
            gateOpenAmount = min(1.0, max(0.0, gateOpenAmount))
            if gateTimer <= 0 {
                gateOpenAmount = 1.0
                gateState = .open
                gateTimer = gateStayOpenDuration
            }

        case .open:
            gateOpenAmount = 1.0
            if gateTimer <= 0 {
                gateState = .closing
                gateTimer = gateCloseDuration
            }

        case .closing:
            gateOpenAmount = CGFloat(gateTimer / gateCloseDuration)
            gateOpenAmount = min(1.0, max(0.0, gateOpenAmount))
            if gateTimer <= 0 {
                gateOpenAmount = 0
                gateState = .closed
                gateTimer = gateStayClosedDuration
            }
        }

        updateGateDoorPositions()
    }

    // MARK: - Fence & gate collision

    /// Checks whether a cow at the given x position fits through the current gate opening.
    private func cowCanPassGate(cowX: CGFloat) -> Bool {
        let halfOpening = currentGateOpening / 2
        let gateLeft = gateCenterX - halfOpening
        let gateRight = gateCenterX + halfOpening
        let cowHalf = cowRadius * 0.8
        return (cowX - cowHalf >= gateLeft) && (cowX + cowHalf <= gateRight)
    }

    // MARK: - Update loop

    /// Per-frame update: advances difficulty, gate, cow spawning, and cow movement/state.
    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        elapsedTime += dt

        let newLevel = Int(elapsedTime / difficultyInterval)
        if newLevel > difficultyLevel {
            difficultyLevel = newLevel
        }

        updateGate(dt: dt)

        timeSinceLastSpawn += dt
        if timeSinceLastSpawn >= currentSpawnInterval {
            timeSinceLastSpawn = 0
            spawnCow()
        }

        for node in children {
            if node.name == "cow" {
                updateWanderingCow(node, dt: dt)
            } else if node.name == "drowningCow" {
                updateDrowningCow(node, dt: dt)
            }
        }
    }

    /// Moves a wandering cow based on its velocity, applies herding repulsion from the farmer,
    /// and checks for fence/gate collision or falling into the ditch.
    private func updateWanderingCow(_ cow: SKNode, dt: TimeInterval) {
        guard let data = cow.userData else { return }

        var vx = (data["velocityX"] as? CGFloat) ?? 0
        var vy = (data["velocityY"] as? CGFloat) ?? -currentCowSpeed
        var wanderTimer = (data["wanderTimer"] as? TimeInterval) ?? 0

        wanderTimer += dt
        if wanderTimer > 1.5 {
            wanderTimer = 0
            vx = CGFloat.random(in: -20...20)
            vy = -currentCowSpeed + CGFloat.random(in: -10...5)

            // Occasional moo (~15% chance per wander cycle)
            if Float.random(in: 0...1) < 0.15 {
                SoundManager.shared.playMoo()
            }
        }

        let dx = cow.position.x - farmer.position.x
        let dy = cow.position.y - farmer.position.y
        let dist = hypot(dx, dy)

        if dist < herdingRadius && dist > 0 {
            let strength = herdingForce * (1.0 - dist / herdingRadius)
            vx += (dx / dist) * strength * 60
            vy += (dy / dist) * strength * 60
        }

        var newX = cow.position.x + vx * CGFloat(dt)
        var newY = cow.position.y + vy * CGFloat(dt)

        if newX < cowRadius {
            newX = cowRadius
            vx = abs(vx)
        } else if newX > size.width - cowRadius {
            newX = size.width - cowRadius
            vx = -abs(vx)
        }

        let wasBelowFence = cow.position.y < fenceY
        let isAtFence = newY >= fenceY - cowRadius && wasBelowFence

        if isAtFence {
            if cowCanPassGate(cowX: newX) {
                cow.position = CGPoint(x: newX, y: fenceY + cowRadius + 5)
                cowReachedSafety(cow)
                return
            } else {
                newY = fenceY - cowRadius - 1
                vy = -abs(vy) * 0.5
            }
        }

        cow.position = CGPoint(x: newX, y: newY)

        cow.userData?["velocityX"] = vx
        cow.userData?["velocityY"] = vy
        cow.userData?["wanderTimer"] = wanderTimer

        if newY <= ditchHeight + cowRadius {
            cowFellInDitch(cow)
        }
    }

    /// Counts down the drowning timer for a cow in the ditch and triggers drowning if time expires.
    private func updateDrowningCow(_ cow: SKNode, dt: TimeInterval) {
        guard let data = cow.userData else { return }
        var timer = (data["drownTimer"] as? TimeInterval) ?? 0

        timer -= dt
        cow.userData?["drownTimer"] = timer

        if let label = cow.childNode(withName: "countdownLabel") as? SKLabelNode {
            label.text = String(format: "%.1f", max(0, timer))
        }

        if timer <= 0 {
            cowDrowned(cow)
        }
    }
}
