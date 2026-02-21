import SpriteKit

/// Centralized texture cache and sprite factory for all game visuals.
final class SpriteLoader {

    static let shared = SpriteLoader()

    private var cache: [String: SKTexture] = [:]

    private init() {}

    /// Returns a cached texture for the given asset name.
    func texture(_ name: String) -> SKTexture {
        if let tex = cache[name] { return tex }
        let tex = SKTexture(imageNamed: name)
        tex.filteringMode = .linear
        cache[name] = tex
        return tex
    }

    /// Preloads a batch of textures for smoother first-frame rendering.
    func preload(_ names: [String], completion: @escaping () -> Void) {
        let textures = names.map { texture($0) }
        SKTexture.preload(textures) { completion() }
    }

    // MARK: - Cow Sprites

    func cowSprite() -> SKSpriteNode {
        let variant = Int.random(in: 1...2)
        let sprite = SKSpriteNode(texture: texture("cow_walk_\(variant)"))
        sprite.name = "cow"
        sprite.setScale(0.8)
        return sprite
    }

    func cowDrowningTexture() -> SKTexture {
        return texture("cow_drowning")
    }

    func cowWalkTexture() -> SKTexture {
        let variant = Int.random(in: 1...2)
        return texture("cow_walk_\(variant)")
    }

    // MARK: - Farmer Sprite

    func farmerSprite() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture("farmer"))
        sprite.name = "farmer"
        sprite.setScale(0.55)
        return sprite
    }

    // MARK: - Background Tiles

    func backgroundGrassTile() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("background_grass"))
    }

    func safePastureTile() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("safe_pasture"))
    }

    // MARK: - Ditch

    func ditchWaterSprite(frame: Int) -> SKSpriteNode {
        return SKSpriteNode(texture: texture("ditch_water_\(frame)"))
    }

    func ditchWaterTextures() -> [SKTexture] {
        return (1...3).map { texture("ditch_water_\($0)") }
    }

    func ditchEdgeSprite() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("ditch_edge"))
    }

    // MARK: - Fence

    func fencePostSprite() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("fence_post"))
    }

    func fenceRailSprite() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("fence_rail"))
    }

    // MARK: - Gate

    func gateDoorSprite() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("gate_door"))
    }

    func gatePostSprite() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("gate_post"))
    }

    func gateIndicatorTexture(open: Bool) -> SKTexture {
        return texture(open ? "gate_indicator_open" : "gate_indicator_closed")
    }

    // MARK: - Clouds

    func cloudSprite(variant: Int) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture("cloud_\(variant)"))
        sprite.alpha = 0.8
        return sprite
    }

    // MARK: - UI Elements

    func titleLogo() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("title_logo"))
    }

    func playButton() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture("button_play"))
        sprite.name = "playButton"
        return sprite
    }

    func replayButton() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture("button_replay"))
        sprite.name = "replayButton"
        return sprite
    }

    func heartSprite(full: Bool) -> SKSpriteNode {
        return SKSpriteNode(texture: texture(full ? "heart_full" : "heart_empty"))
    }

    func scoreBadge() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("score_badge"))
    }

    func gameOverBanner() -> SKSpriteNode {
        return SKSpriteNode(texture: texture("game_over_banner"))
    }
}
