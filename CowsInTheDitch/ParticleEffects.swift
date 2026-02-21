import SpriteKit

/// Factory for self-removing SKEmitterNode particle effects.
enum ParticleEffects {

    /// Water splash when a cow falls into the ditch.
    static func waterSplash(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_splash")
        emitter.position = position
        emitter.zPosition = 12

        emitter.particleBirthRate = 30
        emitter.numParticlesToEmit = 15
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3

        emitter.emissionAngleRange = .pi
        emitter.emissionAngle = .pi / 2
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40

        emitter.yAcceleration = -200

        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 0.6
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.3

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)

        autoRemove(emitter, after: 1.5)
        return emitter
    }

    /// Dust puff when farmer is dragged.
    static func dustPuff(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_dust")
        emitter.position = position
        emitter.zPosition = 4

        emitter.particleBirthRate = 20
        emitter.numParticlesToEmit = 8
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2

        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 15

        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = 0.3

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)

        autoRemove(emitter, after: 1.0)
        return emitter
    }

    /// Celebration stars when a cow reaches safety.
    static func celebrationStars(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_star")
        emitter.position = position
        emitter.zPosition = 14

        emitter.particleBirthRate = 25
        emitter.numParticlesToEmit = 12
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3

        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 30

        emitter.yAcceleration = -50

        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.2

        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 2.0

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)

        autoRemove(emitter, after: 1.5)
        return emitter
    }

    /// Drowning bubbles rising from a cow in the ditch.
    static func drowningBubbles(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_sparkle")
        emitter.position = position
        emitter.zPosition = 4

        emitter.particleBirthRate = 5
        emitter.numParticlesToEmit = 0 // continuous until removed
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4

        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10

        emitter.particlePositionRange = CGVector(dx: 20, dy: 0)

        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.3

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.8)

        return emitter
    }

    /// Golden burst for new high score.
    static func goldenBurst(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_star")
        emitter.position = position
        emitter.zPosition = 16

        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5

        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50

        emitter.yAcceleration = -80

        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.6
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.2

        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3.0

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0)
        emitter.particleColorRedRange = 0.1
        emitter.particleColorGreenRange = 0.2

        autoRemove(emitter, after: 2.5)
        return emitter
    }

    /// Grass kick particles.
    static func grassKick(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SpriteLoader.shared.texture("particle_grass")
        emitter.position = position
        emitter.zPosition = 4

        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 6
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20

        emitter.yAcceleration = -150

        emitter.particleAlphaSpeed = -1.2
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3

        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 4.0

        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 0.3, green: 0.7, blue: 0.2, alpha: 1.0)

        autoRemove(emitter, after: 1.0)
        return emitter
    }

    // MARK: - Helper

    private static func autoRemove(_ emitter: SKEmitterNode, after seconds: TimeInterval) {
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: seconds),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
}
