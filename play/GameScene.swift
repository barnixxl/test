//
//  GameScene.swift
//  play
//
//  Created by миша on 16.08.24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game objects
    private var airplane: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    
    // Game state
    private var score = 0
    private var isGameOver = false
    
    // Physics categories
    private let airplaneCategory: UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    private let groundCategory: UInt32 = 0x1 << 2
    
    // Game settings
    private let airplaneSpeed: CGFloat = 200
    private let obstacleSpeed: CGFloat = 150
    private let obstacleSpawnInterval: TimeInterval = 1.5
    
    override func didMove(to view: SKView) {
        // Set up physics world
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Set up background
        backgroundColor = .skyBlue
        
        // Create airplane
        createAirplane()
        
        // Create ground
        createGround()
        
        // Create score label
        createScoreLabel()
        
        // Create game over label
        createGameOverLabel()
        
        // Start spawning obstacles
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnObstacle),
                SKAction.wait(forDuration: obstacleSpawnInterval)
            ])
        ))
    }
    
    private func createAirplane() {
        airplane = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 30))
        airplane.position = CGPoint(x: frame.midX, y: frame.midY)
        airplane.zPosition = 1
        
        // Set up physics body
        airplane.physicsBody = SKPhysicsBody(rectangleOf: airplane.size)
        airplane.physicsBody?.categoryBitMask = airplaneCategory
        airplane.physicsBody?.contactTestBitMask = obstacleCategory | groundCategory
        airplane.physicsBody?.collisionBitMask = groundCategory
        airplane.physicsBody?.allowsRotation = false
        airplane.physicsBody?.isDynamic = true
        
        addChild(airplane)
    }
    
    private func createGround() {
        let ground = SKSpriteNode(color: .green, size: CGSize(width: frame.width, height: 50))
        ground.position = CGPoint(x: frame.midX, y: 25)
        ground.zPosition = 1
        
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.isDynamic = false
        
        addChild(ground)
    }
    
    private func createScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Счёт: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
    
    private func createGameOverLabel() {
        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "Игра окончена\nНажмите, чтобы начать заново"
        gameOverLabel.fontSize = 30
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 2
        gameOverLabel.isHidden = true
        addChild(gameOverLabel)
    }
    
    private func spawnObstacle() {
        guard !isGameOver else { return }
        
        let obstacle = SKSpriteNode(color: .brown, size: CGSize(width: 30, height: 100))
        obstacle.position = CGPoint(x: frame.maxX + obstacle.size.width,
                                  y: CGFloat.random(in: obstacle.size.height...frame.maxY - obstacle.size.height))
        obstacle.zPosition = 1
        
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.isDynamic = false
        
        addChild(obstacle)
        
        let moveAction = SKAction.moveBy(x: -(frame.width + obstacle.size.width * 2),
                                       y: 0,
                                       duration: TimeInterval(frame.width / obstacleSpeed))
        let removeAction = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
            return
        }
        
        // Move airplane up
        let moveUp = SKAction.moveBy(x: 0, y: 100, duration: 0.5)
        moveUp.timingMode = .easeOut
        airplane.run(moveUp)
    }
    
    private func restartGame() {
        // Reset game state
        score = 0
        isGameOver = false
        scoreLabel.text = "Счёт: 0"
        gameOverLabel.isHidden = true
        
        // Reset airplane position
        airplane.position = CGPoint(x: frame.midX, y: frame.midY)
        airplane.physicsBody?.velocity = .zero
        
        // Remove all obstacles
        removeAllObstacles()
    }
    
    private func removeAllObstacles() {
        enumerateChildNodes(withName: "obstacle") { node, _ in
            node.removeFromParent()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        // Check if airplane passed any obstacles
        enumerateChildNodes(withName: "obstacle") { node, _ in
            if node.position.x < self.airplane.position.x && !node.userData?["scored"] as? Bool ?? false {
                self.score += 1
                self.scoreLabel.text = "Счёт: \(self.score)"
                node.userData = ["scored": true]
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == airplaneCategory | obstacleCategory ||
           collision == airplaneCategory | groundCategory {
            gameOver()
        }
    }
    
    private func gameOver() {
        isGameOver = true
        gameOverLabel.isHidden = false
    }
}

extension UIColor {
    static let skyBlue = UIColor(red: 0.529, green: 0.808, blue: 0.922, alpha: 1.0)
}
