//
//  GameScene.swift
//  Monkey
//
//  Created by Ellyssin G. on 3/12/15.
//  Copyright (c) 2015 Bleu Bee LLC. All rights reserved.
//

import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let background = SKSpriteNode(imageNamed:"environment")
    
    // 1
    let player = SKSpriteNode(imageNamed: "monkeyThrow_Animation_1")
    
    let textureAtlas = SKTextureAtlas(named:"monkey.atlas")
    var spriteArray = Array<SKTexture>()
    
    override func didMoveToView(view: SKView) {
        
        background.size = self.size
        background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        addChild(background)

        // 3
        player.position = CGPoint(x: self.size.width - player.size.width/2 + 20,
            y: player.size.height/2 + 35)
        player.name = "PlayerSprite"
        addChild(player)
        
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addTourist),
                SKAction.waitForDuration(1.0)
                ])
            ))
    }
    
    func throw() {
        let playerThrow = SKAction.animateWithTextures([
            SKTexture(imageNamed: "monkeyThrow_Animation_1"),
            SKTexture(imageNamed: "monkeyThrow_Animation_2"),
            SKTexture(imageNamed: "monkeyThrow_Animation_3"),
            SKTexture(imageNamed: "monkeyThrow_Animation_1")
            ], timePerFrame: 0.03)
        
        let sequence = SKAction.sequence([playerThrow])

        //let run = SKAction.repeatActionForever(playerThrow)
        
        player.runAction(sequence, withKey: "running")
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addTourist() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "tourist")
        
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size) // 1
        monster.physicsBody?.dynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: size.height/2 + monster.size.height, max: size.height - monster.size.height/2)
        //let actualY = size.height/2 + monster.size.height
        let actualX = random(min: monster.size.width/2, max: size.width - monster.size.width/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: actualX, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        //let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionFade = SKAction.fadeAlphaTo(0, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        monster.runAction(SKAction.sequence([actionFade, actionMoveDone]))
        
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        println("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0) &&
            (secondBody.node != nil)
            ) {
                projectileDidCollideWithMonster(firstBody.node as SKSpriteNode, monster: secondBody.node as SKSpriteNode)
        }
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // 1 - Choose one of the touches to work with
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        
        let touchedNode: SKSpriteNode = self.nodeAtPoint(touchLocation) as SKSpriteNode
        
        if (touchedNode.name == "PlayerSprite") {
            throw()
            
            let projectile = SKSpriteNode(imageNamed: "shit")
            let position = CGPointMake(player.position.x, player.position.y + 30)
            projectile.position = position

            projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
            projectile.physicsBody?.dynamic = true
            projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
            projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
            projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
            projectile.physicsBody?.usesPreciseCollisionDetection = true

            // 3 - Determine offset of location to projectile
            //let offset = touchLocation - projectile.position
            //let position = player.position

            // 4 - Bail out if you are shooting down or backwards
            //if (offset.x < 0) { return }

            // 5 - OK to add now - you've double checked position
            addChild(projectile)

            // 6 - Get the direction of where to shoot
            //let direction = offset.normalized()

            // 7 - Make it shoot far enough to be guaranteed off screen
            //let shootAmount = direction * 1000
            

            // 8 - Add the shoot amount to the current position
            //let realDest = shootAmount + projectile.position
            let realDest = CGPointMake(position.x, self.size.height)
            
            // 9 - Create the actions
            let actionMove = SKAction.moveTo(realDest, duration: 1.0)
            let actionScale = SKAction.scaleBy(0.2, duration: 1.0)
            let actionMoveDone = SKAction.removeFromParent()
            projectile.runAction(SKAction.sequence([actionScale]))
            projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        }
        
    }
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        
//        throw()
//        
//        // 1 - Choose one of the touches to work with
//        let touch = touches.anyObject() as UITouch
//        let touchLocation = touch.locationInNode(self)
//        
//        // 2 - Set up initial location of projectile
//        let projectile = SKSpriteNode(imageNamed: "projectile")
//        projectile.position = player.position
//        
//        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
//        projectile.physicsBody?.dynamic = true
//        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
//        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
//        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
//        projectile.physicsBody?.usesPreciseCollisionDetection = true
//        
//        // 3 - Determine offset of location to projectile
//        let offset = touchLocation - projectile.position
//        
//        // 4 - Bail out if you are shooting down or backwards
//        if (offset.x < 0) { return }
//        
//        // 5 - OK to add now - you've double checked position
//        addChild(projectile)
//        
//        // 6 - Get the direction of where to shoot
//        let direction = offset.normalized()
//        
//        // 7 - Make it shoot far enough to be guaranteed off screen
//        let shootAmount = direction * 1000
//        
//        // 8 - Add the shoot amount to the current position
//        let realDest = shootAmount + projectile.position
//        
//        // 9 - Create the actions
//        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
//        let actionMoveDone = SKAction.removeFromParent()
//        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
}
