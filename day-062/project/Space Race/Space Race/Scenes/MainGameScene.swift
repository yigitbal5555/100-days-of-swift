//
//  MainGameScene.swift
//  Space Race
//
//  Created by Brian Sipple on April 19, 2019.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import SpriteKit
import GameplayKit


class MainGameScene: SKScene {
    enum GameplayState {
        case inProgress
        case over
    }
    
    enum BitMask {
        static let enemy: UInt32 = 1
    }
    
    var enemySpawnInterval = 1.0 {
        didSet { makeGameTimer(spawnInterval: enemySpawnInterval) }
    }
    
    var enemiesCreated = 0 {
        didSet {
            if enemiesCreated % 20 == 0 {
                // decrement the spawn timer on every 20th enemy
                enemySpawnInterval -= 0.1
            }
        }
    }
    
    lazy var scoreLabel: SKLabelNode = makeScoreLabel()
    lazy var starfield: SKEmitterNode = makeStarfieldBackground()
    lazy var playerShip: SKSpriteNode = makePlayerShip()
    
    var gameTimer: Timer!
    
    lazy var sceneCenterPoint = CGPoint(x: frame.midX, y: frame.midY)
    
    var currentGameplayState: GameplayState = .inProgress {
        didSet { gameplayStateChanged() }
    }
    
    var currentScore = 0 {
        didSet {
            self.scoreLabel.text = "Current score: \(currentScore)"
        }
    }
}


// MARK: - Computed Properties

extension MainGameScene {
    var enemiesInSpace: [SKSpriteNode] {
        return children
            .compactMap { $0 as? SKSpriteNode }
            .filter { $0.name == NodeName.enemy }
    }
    
    var pastEnemies: [SKSpriteNode] {
        return enemiesInSpace.filter { ($0.position.x + $0.size.width / 2) < 0 }
    }
    
    var shipScreenBounds: (top: CGFloat, bottom: CGFloat) {
        return (frame.maxY - playerShip.size.height, playerShip.size.height)
    }
}


// MARK: - Lifecycle

extension MainGameScene {
    
    override func update(_ currentTime: TimeInterval) {
        guard currentGameplayState == .inProgress else { return }
        
        currentScore += 1
        checkForPastEnemies()
    }
    
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        addChild(starfield)
        addChild(scoreLabel)
        addChild(playerShip)
        
        currentScore = 0
        enemySpawnInterval = 1.0
    }
}


// MARK: - Event handling

extension MainGameScene {
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            currentGameplayState == .inProgress,
            var touchLocation = touches.first?.location(in: self),
            didTouchPlayer(touchLocation)
        else {
            return
        }
        
        if touchLocation.y > shipScreenBounds.top {
            touchLocation.y = shipScreenBounds.top
        } else if touchLocation.y < shipScreenBounds.bottom {
            touchLocation.y = shipScreenBounds.bottom
        }
        
        playerShip.position = touchLocation
    }
    
    
    func shipDestroyed(by enemy: SKNode) {
        guard let explosion = SKEmitterNode(fileNamed: "explosion") else {
            preconditionFailure("Failed to load explosion emitter effect")
        }
        
        explosion.position = playerShip.position
        
        remove(node: enemy)
        remove(node: playerShip)
        addChild(explosion)
        
        currentGameplayState = .over
    }
    
    
    func gameplayStateChanged() {
        switch currentGameplayState {
        case .inProgress:
            break
        case .over:
            gameTimer.invalidate()
        }
    }
}


// MARK: - SKPhysicsContactDelegate

extension MainGameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard
            let nodeA = contact.bodyA.node,
            let nodeB = contact.bodyB.node
        else {
            return
        }
        
        if [nodeA.name, nodeB.name].contains(NodeName.playerShip) {
            let collidingNode = nodeA.name == NodeName.playerShip ? nodeB : nodeA
            
            shipDestroyed(by: collidingNode)
        }
    }
}


// MARK: - Private Helper Methods

private extension MainGameScene {
    func makeScoreLabel() -> SKLabelNode {
        let scoreLabel = SKLabelNode()
        
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.horizontalAlignmentMode = .left
        
        return scoreLabel
    }
    
    
    func makePlayerShip() -> SKSpriteNode {
        let playerShip = SKSpriteNode(imageNamed: "player")
        
        playerShip.position = CGPoint(x: 100.0, y: sceneCenterPoint.y)
        playerShip.physicsBody = SKPhysicsBody(texture: playerShip.texture!, size: playerShip.size)
        playerShip.physicsBody?.contactTestBitMask = BitMask.enemy
        playerShip.name = NodeName.playerShip
        
        return playerShip
    }
    
    
    func makeStarfieldBackground() -> SKEmitterNode {
        guard let starfield = SKEmitterNode(fileNamed: "Starfield") else {
            preconditionFailure("Failed to starfield emitter effect")
        }
        
        starfield.position = CGPoint(x: frame.maxX, y: sceneCenterPoint.y)
        starfield.zPosition = -1
        
        // cause the particles to spread out over our background
        starfield.advanceSimulationTime(10)
        
        return starfield
    }
    

    func makeGameTimer(spawnInterval enemySpawnInterval: Double) {
        if gameTimer != nil {
            gameTimer.invalidate()
        }
        
        gameTimer = Timer.scheduledTimer(
            timeInterval: enemySpawnInterval,
            target: self,
            selector: #selector(spawnEnemy),
            userInfo: nil,
            repeats: true
        )
    }
    
    
    @objc func spawnEnemy() {
        let enemyType = EnemyType.allCases.randomElement()!
        let enemy = SKSpriteNode(imageNamed: enemyType.rawValue)
        let enemyWidth = CGFloat(enemy.size.width)
        let enemyHeight = CGFloat(enemy.size.height)
        
        let xPos = frame.maxX + enemyWidth
        let yPos = CGFloat.random(in: enemyHeight...(frame.maxY - enemyHeight))
        
        enemy.position = CGPoint(x: xPos, y: yPos)
        enemy.name = NodeName.enemy
        
        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        enemy.physicsBody?.categoryBitMask = BitMask.enemy
        enemy.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        enemy.physicsBody?.angularDamping = 0
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.angularVelocity = 5
        
        enemiesCreated += 1
        addChild(enemy)
    }
    
    
    func checkForPastEnemies() {
        pastEnemies.forEach(remove)
    }
    
    
    func remove(node: SKNode) {
        node.removeFromParent()
    }
    
    
    func didTouchPlayer(_ touchLocation: CGPoint) -> Bool {
        return playerShip.contains(touchLocation)
    }
}
