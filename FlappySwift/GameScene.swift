//
//  GameScene.swift
//  FlappySwift
//
//  Created by rgb on 8/20/14.
//  Copyright (c) 2014 rgb. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode()
    var skyColor = SKColor()
    var verticalPipeGap = 170.0
    var pipeTexture1 = SKTexture()
    var pipeTexture2 = SKTexture()
    var movePipesAndRemove = SKAction()
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    var moving = SKNode()
    var CanRestart = false
    var pipes = SKNode()
    
    var scoreLabelNode = SKLabelNode()
    var score = NSInteger()
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        self.addChild(moving)
        moving.addChild(pipes)
        
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        self.physicsWorld.contactDelegate = self
        
        skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
         /* BIRD*/
        var birdTexture1 = SKTexture(imageNamed:"Bird1")
        birdTexture1.filteringMode = SKTextureFilteringMode.Nearest
        
        var birdTexture2 = SKTexture(imageNamed:"Bird2")
        birdTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
        var animation = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        var flap=SKAction.repeatActionForever(animation)
        
        bird = SKSpriteNode(texture:birdTexture1)
        bird.position = CGPoint(x: self.frame.size.width / 2.8 , y: CGRectGetMidY(self.frame))
        bird.runAction(flap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody.dynamic = true
        bird.physicsBody.allowsRotation = false
        
        bird.physicsBody.categoryBitMask = birdCategory
        bird.physicsBody.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
         /*GROUND*/
        var groundTexture = SKTexture(imageNamed:"Ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        var moveGroundSprite = SKAction.moveByX(-groundTexture.size().width, y: 0, duration: NSTimeInterval(0.01 * groundTexture.size().width))
        var resetGroundSprite = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        var moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        
        
        
        for var i:CGFloat = 0; i<2 + self.frame.size.width / (groundTexture.size().width); ++i {
            var sprite = SKSpriteNode(texture : groundTexture)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        var dummy = SKNode()
        dummy.position = CGPointMake(0, groundTexture.size().height / 2)
        dummy.physicsBody = SKPhysicsBody(rectangleOfSize:CGSizeMake(self.frame.size.width, groundTexture.size().height))
        dummy.physicsBody.dynamic = false
        dummy.physicsBody.categoryBitMask = worldCategory
        self.addChild(dummy)
        
         /*SKYLINE*/
        
        var skylineTexture = SKTexture(imageNamed:"Skyline")
        skylineTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        var moveSkylineSprite = SKAction.moveByX(-skylineTexture.size().width, y: 0, duration: NSTimeInterval(0.01 * skylineTexture.size().width))
        var resetSkylineSprite = SKAction.moveByX(skylineTexture.size().width, y: 0, duration: 0.0)
        var moveSkylineSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkylineSprite,resetSkylineSprite]))
        
       
        for var i:CGFloat = 0; i<2 + self.frame.size.width / (skylineTexture.size().width); ++i {
            
            var sprite = SKSpriteNode(texture : skylineTexture)
            sprite.zPosition = -20
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2 + groundTexture.size().height)
            sprite.runAction(moveSkylineSpritesForever)
           moving.addChild(sprite)
           }
        
        /* PIPES */
        
        pipeTexture1 = SKTexture(imageNamed:"Pipe1")
        pipeTexture1.filteringMode = SKTextureFilteringMode.Nearest
        
        pipeTexture2 = SKTexture(imageNamed:"Pipe2")
        pipeTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
      
        
        var distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTexture1.size().width)
        var movePipes = SKAction.moveByX(-distanceToMove, y:0.0 , duration:NSTimeInterval(0.01 * distanceToMove))
        var removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes,removePipes])
        
        
        var spawn = SKAction.runBlock({() in self.spawnPipes()})
        var delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        var spawnThenDelay = SKAction.sequence([spawn,delay])
        var spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        score = 0
        scoreLabelNode.fontName = "Helvetica-Bold"
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.height / 2)
        scoreLabelNode.fontSize = 200
        scoreLabelNode.alpha = 0.2
        scoreLabelNode.zPosition = -40
        scoreLabelNode.text = "\(score)"
        self.addChild(scoreLabelNode)
        
        
            
    }
    
    func spawnPipes(){
        
        var pipePair = SKNode()
        pipePair.position = CGPointMake(self.frame.size.width + pipeTexture1.size().width * 2.0,0)
        pipePair.zPosition = -10
        
        var height = UInt32(self.frame.height / 3)
        var y = arc4random() % height
        
        
        
        var pipe1 = SKSpriteNode(texture: pipeTexture1)
        pipe1.position = CGPointMake(0.0, CGFloat(y))
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size)
        pipe1.physicsBody.dynamic = false
        pipe1.physicsBody.categoryBitMask = pipeCategory
        pipe1.physicsBody.contactTestBitMask = birdCategory
        pipePair.addChild(pipe1)
        
        var pipe2 = SKSpriteNode(texture: pipeTexture2)
        pipe2.position = CGPointMake(0.0, CGFloat(y) + pipe1.size.height + CGFloat(verticalPipeGap))
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipe2.size)
        pipe2.physicsBody.dynamic = false
        pipe2.physicsBody.categoryBitMask = pipeCategory
        pipe2.physicsBody.contactTestBitMask = birdCategory
        pipePair.addChild(pipe2)
        
        var contactNode = SKNode()
        contactNode.position = CGPointMake(pipe1.size.width + bird.size.width / 2, CGRectGetMidY(self.frame))
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize:CGSizeMake(pipe1.size.width, self.frame.size.height))
        contactNode.physicsBody.dynamic = false
        contactNode.physicsBody.categoryBitMask = scoreCategory
        contactNode.physicsBody.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
            
        
        pipePair.runAction(movePipesAndRemove)
        
        pipes.addChild(pipePair)
    }
    
    func resetScene(){
    
    
        bird.position = CGPoint(x: self.frame.size.width/2.8, y: CGRectGetMidY(self.frame))
        bird.physicsBody.velocity = CGVectorMake(0, 0)
        bird.physicsBody.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        
        
        
        pipes.removeAllChildren()
        
        CanRestart = false
        
        moving.speed = 1
        
        score = 0
        scoreLabelNode.text = "\(score)"
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        if(moving.speed > 0){
        
            bird.physicsBody.velocity = CGVectorMake(0, 0)
            bird.physicsBody.applyImpulse(CGVectorMake(0, 8))
            
            }else if(CanRestart){
            
            self.resetScene()
            }
   
    }
    
    func clamp ( min:CGFloat, max:CGFloat, value:CGFloat) ->CGFloat {
    
       if (value > max){
            return max
        }
        else if (value < min){
            return min
        }else  {
        return value
      }
   
    }
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if(moving.speed > 0) {
            
            bird.zRotation = self.clamp(-1, max: 0.5, value: bird.physicsBody.velocity.dy * (bird.physicsBody.velocity.dy < 0 ? 0.003:0.001))
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        
        if(moving.speed > 0){
            
           if((contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory)
            {
                
                    score++
                scoreLabelNode.text = "\(score)"
                
                
        }else {
            
            moving.speed = 0
            
            bird.physicsBody.collisionBitMask = worldCategory
            
            var rotateBird = SKAction.rotateByAngle(0.01, duration: 0.03)
            var stopBird = SKAction.runBlock({() in self.killBirdSpeed()})
            var birdSequence = SKAction.sequence([rotateBird,stopBird])
            bird.runAction(birdSequence)
            
            self.removeActionForKey("flash")
            var turnBackgroundRed = SKAction.runBlock({() in self.setBackgroundRed()})
            var wait = SKAction.waitForDuration(0.05)
            var turnBackgroundWhite = SKAction.runBlock({()in self.setBackgroundWhite()})
            var turnBackgroundColorSky = SKAction.runBlock({()in self.setBackgroundSky()})
            var sequenceOfActions = SKAction.sequence([turnBackgroundRed,wait,turnBackgroundWhite,wait,turnBackgroundColorSky])
            var repeatSequence = SKAction.repeatAction(sequenceOfActions, count: 4)
            var canRestartAction = SKAction.runBlock({() in self.letItRestart()})
            var groupOfAction = SKAction.group([repeatSequence,canRestartAction])
            
            
            self.runAction(groupOfAction, withKey: "flash")
            
            }
        }
       
    }
    
    func killBirdSpeed() {
        bird.speed = 0
        
        }
    func letItRestart() {
        CanRestart = true
        }
    
    func setBackgroundRed() {
        self.backgroundColor = UIColor.redColor()
        
    }
    func setBackgroundWhite() {
        self.backgroundColor = UIColor.whiteColor()
        
    }
    
    func setBackgroundSky() {
        self.backgroundColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        
    }

    
}
