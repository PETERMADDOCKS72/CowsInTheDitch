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

    private var farmer: SKNode!
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
    private var leftDoor: SKNode!
    private var rightDoor: SKNode!
    private var gateIndicator: SKShapeNode!

    // MARK: - HUD

    private var scoreLabel: SKLabelNode!
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
        backgroundColor = SKColor(red: 0.3, green: 0.65, blue: 0.15, alpha: 1.0)
        setupDitch()
        setupSafePasture()
        setupFence()
        setupGate()
        setupFarmer()
        setupHUD()
    }

    /// Creates the water-filled ditch at the bottom of the screen with a ripple animation.
    private func setupDitch() {
        let ditch = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: ditchHeight))
        ditch.fillColor = SKColor(red: 0.2, green: 0.35, blue: 0.6, alpha: 1.0)
        ditch.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        ditch.lineWidth = 3
        ditch.name = "ditch"
        addChild(ditch)

        let edge = SKShapeNode(rect: CGRect(x: 0, y: ditchHeight - 2, width: size.width, height: 4))
        edge.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        edge.strokeColor = .clear
        addChild(edge)

        let rippleLabel = SKLabelNode(text: "~ ~ ~ ~ ~ ~ ~ ~ ~ ~")
        rippleLabel.fontSize = 14
        rippleLabel.fontColor = SKColor(red: 0.4, green: 0.55, blue: 0.8, alpha: 0.6)
        rippleLabel.position = CGPoint(x: size.width / 2, y: ditchHeight / 2)
        addChild(rippleLabel)

        let moveLeft = SKAction.moveBy(x: -20, y: 0, duration: 1.5)
        let moveRight = SKAction.moveBy(x: 20, y: 0, duration: 1.5)
        rippleLabel.run(SKAction.repeatForever(SKAction.sequence([moveLeft, moveRight])))
    }

    /// Creates the darker green safe pasture area above the fence with a label.
    private func setupSafePasture() {
        let pastureHeight = size.height - fenceY - fenceThickness
        let pasture = SKShapeNode(rect: CGRect(x: 0, y: fenceY + fenceThickness,
                                                width: size.width, height: pastureHeight))
        pasture.fillColor = SKColor(red: 0.25, green: 0.55, blue: 0.12, alpha: 1.0)
        pasture.strokeColor = .clear
        pasture.zPosition = 0
        addChild(pasture)

        let safeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        safeLabel.text = "SAFE PASTURE"
        safeLabel.fontSize = 16
        safeLabel.fontColor = SKColor(white: 1.0, alpha: 0.35)
        safeLabel.position = CGPoint(x: size.width / 2, y: fenceY + fenceThickness + pastureHeight / 2)
        safeLabel.zPosition = 1
        addChild(safeLabel)
    }

    /// Draws the fence posts, rails, and gate frame posts on either side of the gate opening.
    private func setupFence() {
        let y = fenceY
        let postColor = SKColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1.0)
        let railColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        let postHeight: CGFloat = 36

        let gateLeftEdge = gateCenterX - gateFullWidth / 2
        let gateRightEdge = gateCenterX + gateFullWidth / 2

        drawFenceSection(from: 0, to: gateLeftEdge, y: y, postHeight: postHeight,
                         postColor: postColor, railColor: railColor)

        drawFenceSection(from: gateRightEdge, to: size.width, y: y, postHeight: postHeight,
                         postColor: postColor, railColor: railColor)

        for x in [gateLeftEdge, gateRightEdge] {
            let gatePost = SKShapeNode(rect: CGRect(x: x - 3, y: y - 4, width: 6, height: postHeight + 8))
            gatePost.fillColor = SKColor(red: 0.45, green: 0.25, blue: 0.1, alpha: 1.0)
            gatePost.strokeColor = SKColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
            gatePost.lineWidth = 1
            gatePost.zPosition = 7
            addChild(gatePost)
        }
    }

    /// Draws a horizontal fence section with evenly spaced posts and two rails.
    private func drawFenceSection(from startX: CGFloat, to endX: CGFloat, y: CGFloat,
                                   postHeight: CGFloat, postColor: SKColor, railColor: SKColor) {
        guard endX > startX else { return }

        let spacing: CGFloat = 35
        var x = startX
        while x <= endX {
            let post = SKShapeNode(rect: CGRect(x: x - 2, y: y, width: 4, height: postHeight))
            post.fillColor = postColor
            post.strokeColor = .clear
            post.zPosition = 6
            addChild(post)
            x += spacing
        }

        for railOffset: CGFloat in [10, 24] {
            let rail = SKShapeNode(rect: CGRect(x: startX, y: y + railOffset,
                                                 width: endX - startX, height: 3))
            rail.fillColor = railColor
            rail.strokeColor = .clear
            rail.zPosition = 6
            addChild(rail)
        }
    }

    /// Creates the two sliding gate doors with cross-braces and the open/closed indicator dot.
    private func setupGate() {
        let y = fenceY
        let doorColor = SKColor(red: 0.65, green: 0.4, blue: 0.15, alpha: 1.0)
        let doorHeight: CGFloat = 32

        leftDoor = SKNode()
        leftDoor.position = CGPoint(x: gateCenterX - gateFullWidth / 2, y: y)
        leftDoor.zPosition = 7

        let leftPanel = SKShapeNode(rect: CGRect(x: 0, y: 0,
                                                   width: gateFullWidth / 2, height: doorHeight))
        leftPanel.fillColor = doorColor
        leftPanel.strokeColor = SKColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        leftPanel.lineWidth = 1.5
        leftPanel.name = "panel"
        leftDoor.addChild(leftPanel)

        let leftBrace = SKShapeNode()
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: 2, y: 2))
        leftPath.addLine(to: CGPoint(x: gateFullWidth / 2 - 2, y: doorHeight - 2))
        leftBrace.path = leftPath
        leftBrace.strokeColor = SKColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 0.7)
        leftBrace.lineWidth = 2
        leftDoor.addChild(leftBrace)

        addChild(leftDoor)

        rightDoor = SKNode()
        rightDoor.position = CGPoint(x: gateCenterX + gateFullWidth / 2, y: y)
        rightDoor.zPosition = 7

        let rightPanel = SKShapeNode(rect: CGRect(x: -gateFullWidth / 2, y: 0,
                                                    width: gateFullWidth / 2, height: doorHeight))
        rightPanel.fillColor = doorColor
        rightPanel.strokeColor = SKColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        rightPanel.lineWidth = 1.5
        rightPanel.name = "panel"
        rightDoor.addChild(rightPanel)

        let rightBrace = SKShapeNode()
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: -gateFullWidth / 2 + 2, y: 2))
        rightPath.addLine(to: CGPoint(x: -2, y: doorHeight - 2))
        rightBrace.path = rightPath
        rightBrace.strokeColor = SKColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 0.7)
        rightBrace.lineWidth = 2
        rightDoor.addChild(rightBrace)

        addChild(rightDoor)

        gateIndicator = SKShapeNode(circleOfRadius: 5)
        gateIndicator.position = CGPoint(x: gateCenterX, y: fenceY + 42)
        gateIndicator.zPosition = 8
        gateIndicator.strokeColor = .clear
        addChild(gateIndicator)

        updateGateDoorPositions()
    }

    /// Positions the left and right gate doors based on the current open amount and updates the indicator color.
    private func updateGateDoorPositions() {
        let halfSlide = (gateFullWidth / 2) * gateOpenAmount
        leftDoor.position.x = gateCenterX - gateFullWidth / 2 - halfSlide
        rightDoor.position.x = gateCenterX + gateFullWidth / 2 + halfSlide

        let cowCanPass = currentGateOpening > cowRadius * 2.2
        gateIndicator.fillColor = cowCanPass
            ? SKColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 0.8)
            : SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.8)
    }

    /// Creates the farmer sprite with body, hat, and eyes at the center of the play field.
    private func setupFarmer() {
        farmer = SKNode()
        farmer.position = CGPoint(x: size.width / 2, y: (ditchHeight + fenceY) / 2)
        farmer.name = "farmer"

        let body = SKShapeNode(circleOfRadius: farmerRadius)
        body.fillColor = SKColor(red: 0.85, green: 0.5, blue: 0.2, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0)
        body.lineWidth = 2
        farmer.addChild(body)

        let hat = SKShapeNode(ellipseOf: CGSize(width: farmerRadius * 1.8, height: farmerRadius * 0.7))
        hat.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1.0)
        hat.strokeColor = SKColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        hat.lineWidth = 1.5
        hat.position = CGPoint(x: 0, y: farmerRadius * 0.4)
        farmer.addChild(hat)

        let leftEye = SKShapeNode(circleOfRadius: 3)
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 1
        leftEye.position = CGPoint(x: -7, y: 2)
        farmer.addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 3)
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 1
        rightEye.position = CGPoint(x: 7, y: 2)
        farmer.addChild(rightEye)

        addChild(farmer)
    }

    /// Creates the score label and lives display at the top of the screen.
    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Saved: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: size.height - 50)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        livesDisplay = SKNode()
        livesDisplay.position = CGPoint(x: size.width - 16, y: size.height - 45)
        livesDisplay.zPosition = 10
        addChild(livesDisplay)
        updateLivesDisplay()
    }

    /// Rebuilds the heart icons in the lives display to reflect the current life count.
    private func updateLivesDisplay() {
        livesDisplay.removeAllChildren()
        for i in 0..<lives {
            let heart = SKLabelNode(text: "\u{2764}\u{FE0F}")
            heart.fontSize = 22
            heart.horizontalAlignmentMode = .right
            heart.position = CGPoint(x: -CGFloat(i) * 30, y: 0)
            livesDisplay.addChild(heart)
        }
    }

    // MARK: - Cow spawning

    /// Creates a new cow with random spots and adds it to the field just below the fence.
    private func spawnCow() {
        let cow = SKNode()
        let spawnX = CGFloat.random(in: cowRadius * 2...(size.width - cowRadius * 2))
        let spawnY = fenceY - cowRadius - 20
        cow.position = CGPoint(x: spawnX, y: spawnY)
        cow.name = "cow"

        let body = SKShapeNode(ellipseOf: CGSize(width: cowRadius * 2.2, height: cowRadius * 1.6))
        body.fillColor = .white
        body.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        body.lineWidth = 2
        cow.addChild(body)

        for _ in 0..<3 {
            let spot = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 6...12),
                                                       height: CGFloat.random(in: 5...9)))
            spot.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.8)
            spot.strokeColor = .clear
            spot.position = CGPoint(x: CGFloat.random(in: -8...8),
                                    y: CGFloat.random(in: -5...5))
            cow.addChild(spot)
        }

        let head = SKShapeNode(circleOfRadius: 7)
        head.fillColor = .white
        head.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        head.lineWidth = 1.5
        head.position = CGPoint(x: 0, y: -cowRadius * 0.6)
        cow.addChild(head)

        let leftEye = SKShapeNode(circleOfRadius: 2)
        leftEye.fillColor = .black
        leftEye.position = CGPoint(x: -3, y: -cowRadius * 0.6 + 2)
        cow.addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 2)
        rightEye.fillColor = .black
        rightEye.position = CGPoint(x: 3, y: -cowRadius * 0.6 + 2)
        cow.addChild(rightEye)

        cow.userData = NSMutableDictionary()
        cow.userData?["velocityX"] = CGFloat.random(in: -15...15)
        cow.userData?["velocityY"] = -currentCowSpeed
        cow.userData?["state"] = "wandering"
        cow.userData?["wanderTimer"] = TimeInterval(0)

        cow.zPosition = 5
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
            cow.setScale(1.0)
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

    /// Transitions a cow into the drowning state with a countdown ring and bobbing animation.
    private func cowFellInDitch(_ cow: SKNode) {
        cow.name = "drowningCow"
        cow.userData?["state"] = "drowning"
        let duration = currentDrowningDuration
        cow.userData?["drownTimer"] = duration

        cow.position.y = ditchHeight / 2
        cow.zPosition = 3

        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.5)
        let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        cow.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "drowning")

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

    /// Plays a celebration animation, increments the score, and removes the cow from the scene.
    private func cowReachedSafety(_ cow: SKNode) {
        cow.name = "safe"
        score += 1
        scoreLabel.text = "Saved: \(score)"

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
