import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Nodes
    var bird = SKSpriteNode()
    var brick = SKSpriteNode()
    var boxes: [SKSpriteNode] = []

    // MARK: - Game Variables
    var birdOriginalPosition: CGPoint!
    var gameStarted = false
    var score = 0
    var bestScore = 0

    // MARK: - UI
    var scoreLabel: SKLabelNode!
    var bestScoreLabel: SKLabelNode!

    // MARK: - Physics Categories
    struct PhysicsCategory {
        static let bird: UInt32 = 1
        static let brick: UInt32 = 2
        static let box: UInt32 = 4
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        setupBird()
        setupBrick()
        setupBoxes()
        setupLabels()
        loadBestScore()
    }

    // MARK: - Setup Functions
    func setupScene() {
        self.scaleMode = .aspectFit
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self
    }

    func setupBird() {
        guard let node = childNode(withName: "bird") as? SKSpriteNode else { return }
        bird = node
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.mass = 0.15
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.collisionBitMask = PhysicsCategory.box
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        birdOriginalPosition = bird.position
    }

    func setupBrick() {
        guard let node = childNode(withName: "brick") as? SKSpriteNode else { return }
        brick = node
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.isDynamic = false
        brick.physicsBody?.affectedByGravity = true
        brick.physicsBody?.allowsRotation = false
        brick.physicsBody?.mass = 1.5
    }

    func setupBoxes() {
        for i in 1...5 {
            if let box = childNode(withName: "box\(i)") as? SKSpriteNode {
                box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                box.physicsBody?.isDynamic = true
                box.physicsBody?.affectedByGravity = true
                box.physicsBody?.allowsRotation = true
                box.physicsBody?.mass = 0.35
                box.physicsBody?.collisionBitMask = PhysicsCategory.bird
                boxes.append(box)
            }
        }
    }

    func setupLabels() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 75
        scoreLabel.fontColor = .black
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY + 200)
        scoreLabel.horizontalAlignmentMode = .center
        addChild(scoreLabel)

        bestScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        bestScoreLabel.fontSize = 40
        bestScoreLabel.fontColor = .black
        bestScoreLabel.position = CGPoint(x: frame.minX + 20, y: frame.maxY - 100)
        bestScoreLabel.horizontalAlignmentMode = .left
        addChild(bestScoreLabel)
    }

    func loadBestScore() {
        bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        bestScoreLabel.text = "Best Score: \(bestScore)"
    }

    func updateBestScore() {
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "bestScore")
            bestScoreLabel.text = "Best Score: \(bestScore)"
        }
    }

    // MARK: - Touch Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted, let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            if touchedNodes.contains(bird) {
                let dx = birdOriginalPosition.x - location.x
                let dy = birdOriginalPosition.y - location.y
                bird.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
                bird.physicsBody?.affectedByGravity = true
                gameStarted = true
            }
        }
    }

    func handleTouch(_ touches: Set<UITouch>) {
        if !gameStarted, let touch = touches.first {
            let location = touch.location(in: self)
            if nodes(at: location).contains(bird) {
                bird.position = location
            }
        }
    }

    // MARK: - Collision Detection
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.bird || contact.bodyB.categoryBitMask == PhysicsCategory.bird {
            score += 1
            scoreLabel.text = "Score: \(score)"
            updateBestScore()
        }
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard gameStarted,
              let velocity = bird.physicsBody?.velocity,
              abs(velocity.dx) < 0.1,
              abs(velocity.dy) < 0.1,
              abs(bird.physicsBody!.angularVelocity) < 0.1 else { return }

        resetGame()
    }

    func resetGame() {
        bird.physicsBody?.velocity = .zero
        bird.physicsBody?.angularVelocity = 0
        bird.physicsBody?.affectedByGravity = false
        bird.position = birdOriginalPosition
        score = 0
        scoreLabel.text = "Score: 0"
        gameStarted = false
    }
}
