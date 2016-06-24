//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Alex on 6/21/16.
//  Copyright (c) 2016 Alex Barcenas. All rights reserved.
//

import AVFoundation
import SpriteKit

enum SequenceType: Int {
    case OneNoBomb, One, TwoWithOneBomb, Two, Three, Four, Chain, FastChain
}

enum ForceBomb {
    case Never, Always, Default
}

class GameScene: SKScene {
    // The label that displays the user's score.
    var gameScore: SKLabelNode!
    // Keeps track of the user's score.
    var score: Int = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    // Displays how many lives the user has left.
    var livesImages = [SKSpriteNode]()
    // Keeps track of the number of lives left.
    var lives = 3
    
    // The background slice.
    var activeSliceBG: SKShapeNode!
    // The foreground slice.
    var activeSliceFG: SKShapeNode!
    // The swipe points for the slices.
    var activeSlicePoints = [CGPoint]()
    
    // Keeps track of whether or not a sound needs to be played for swiping.
    var swooshSoundActive = false
    
    // The sound used for the bomb.
    var bombSoundEffect: AVAudioPlayer!
    
    // The enemies that are currently active in the scene.
    var activeEnemies = [SKSpriteNode]()
    
    // Wait time between destroyed enemies and the new ones being created.
    var popupTime = 0.9
    // The sequence on enemies that are being created.
    var sequence: [SequenceType]!
    // Where in the sequence we currently are.
    var sequencePosition = 0
    // Delay between the enemies created in a chain sequence.
    var chainDelay = 3.0
    // Whether or not the next sequence of enemies is ready to be created.
    var nextSequenceQueued = true
    
    // Keeps track of whether or not the game has ended already.
    var gameEnded = false
    
    /*
     * Function Name: didMoveToView
     * Parameters: view - the view that called this method.
     * Purpose: This method sets up the visual environment of the game and
     *   sets up the enemy sequences that will be used when spawning enemies.
     * Return Value: None
     */
    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .Replace
        background.zPosition = -1
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        createScore()
        createLives()
        createSlices()
        
        sequence = [.OneNoBomb, .OneNoBomb, .TwoWithOneBomb, .TwoWithOneBomb, .Three, .One, .Chain]
        
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        RunAfterDelay(2) { [unowned self] in
            self.tossEnemies()
        }
    }
    
    /*
     * Function Name: touchesEnded
     * Parameters: touches - the touches that occurred at the beginning of the event.
     *   event - the event that represents what the touches are.
     * Purpose: This method resets and adds to the slices point array. Afterwards, this method
     *   redraws the slices and resets the properties associated with the slices.
     * Return Value: None
     */
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        // 1
        activeSlicePoints.removeAll(keepCapacity: true)
        
        // 2
        if let touch = touches.first {
            let location = touch.locationInNode(self)
            activeSlicePoints.append(location)
            
            // 3
            redrawActiveSlice()
            
            // 4
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            
            // 5
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
    }
   
    /*
     * Function Name: update
     * Parameters: currentTime - the current system time.
     * Purpose: This method keeps track of how many enemies are bombs and stops the bomb sound
     *   when there are no longer any bomb enemies. Also remove any enemies that are off of the screen.
     *   The user will lose a life if the enemy removed off the screen was a penguin.
     * Return Value: None
     */
    
    override func update(currentTime: CFTimeInterval) {
        var bombCount = 0
        
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0 {
            // no bombs – stop the fuse sound!
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
        
        if activeEnemies.count > 0 {
            for node in activeEnemies {
                // The node is below the screen.
                if node.position.y < -140 {
                    node.removeAllActions()
                    
                    // The node is a penguin.
                    if node.name == "enemy" {
                        node.name = ""
                        subtractLife()
                        
                        node.removeFromParent()
                        
                        if let index = activeEnemies.indexOf(node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    }
                    // The node is a bomb.
                    else if node.name == "bombContainer" {
                        node.name = ""
                        node.removeFromParent()
                        
                        if let index = activeEnemies.indexOf(node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    }
                }
            }
        } else {
            if !nextSequenceQueued {
                RunAfterDelay(popupTime) { [unowned self] in
                    self.tossEnemies()
                }
                
                nextSequenceQueued = true
            }
        }
    }
    
    /*
     * Function Name: createScore
     * Parameters: None
     * Purpose: This method creates and displays the label that will display the score.
     * Return Value: None
     */
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .Left
        gameScore.fontSize = 48
        
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    /*
     * Function Name: createLives
     * Parameters: None
     * Purpose: This method creates and displays the nodes that display the number of lives.
     * Return Value: None
     */
    
    func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            
            livesImages.append(spriteNode)
        }
    }
    
    /*
     * Function Name: createSlices
     * Parameters: None
     * Purpose: This method creates what the slices will look like.
     * Return Value: None
     */
    
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.whiteColor()
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    /*
     * Function Name: touchesMoved
     * Parameters: touches - the touches that occurred during the event.
     *   event - the event that represents what the touches are.
     * Purpose: This method gets where the user has touched and adds it to the slice points array.
     *   Afterwards, the active slice is redrawn and a sound is played if it is active. This method
     *   also handles when an enemy is swiped by the user.
     * Return Value: None
     */
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameEnded {
            return
        }
        
        guard let touch = touches.first else { return }
        
        let location = touch.locationInNode(self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !swooshSoundActive {
            playSwooshSound()
        }
        
        let nodes = nodesAtPoint(location)
        
        for node in nodes {
            // Handles enemy destruction when the enemy is a penguin.
            if node.name == "enemy" {
                // 1
                let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")!
                emitter.position = node.position
                addChild(emitter)
                
                // 2
                node.name = ""
                
                // 3
                node.physicsBody!.dynamic = false
                
                // 4
                let scaleOut = SKAction.scaleTo(0.001, duration:0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                // 5
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                node.runAction(seq)
                
                // 6
                score += 1
                
                // 7
                let index = activeEnemies.indexOf(node as! SKSpriteNode)!
                activeEnemies.removeAtIndex(index)
                
                // 8
                runAction(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
            }
            // Handles enemy destruction when the enemy is a bomb.
            else if node.name == "bomb" {
                let emitter = SKEmitterNode(fileNamed: "sliceHitBomb")!
                emitter.position = node.parent!.position
                addChild(emitter)
                
                node.name = ""
                node.parent!.physicsBody!.dynamic = false
                
                let scaleOut = SKAction.scaleTo(0.001, duration:0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                
                node.parent!.runAction(seq)
                
                let index = activeEnemies.indexOf(node.parent as! SKSpriteNode)!
                activeEnemies.removeAtIndex(index)
                
                runAction(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                endGame(triggeredByBomb: true)
            }
        }
    }
    
    /*
     * Function Name: touchesEnded
     * Parameters: touches - the touches that occurred at the end of the event.
     *   event - the event that represents what the touches are.
     * Purpose: This method causes the slices created to fade away.
     * Return Value: None
     */
    
    override func touchesEnded(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        activeSliceBG.runAction(SKAction.fadeOutWithDuration(0.25))
        activeSliceFG.runAction(SKAction.fadeOutWithDuration(0.25))
    }
    
    /*
     * Function Name: touchesCanceled
     * Parameters: touches - the touches that occurred at the end of the event.
     *   event - the event that represents what the touches are.
     * Purpose: This method causes the slices created to fade away if they exist.
     * Return Value: None
     */
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if let touches = touches {
            touchesEnded(touches, withEvent: event)
        }
    }
    
    /*
     * Function Name: redrawActiveSlice
     * Parameters: None
     * Purpose: This method ensures that there are at least 2 points and at most 12 points
     *   in the slice points array. Afterwards, the method uses the slice points array to
     *   create a path for both of the slices.
     * Return Value: None
     */
    
    func redrawActiveSlice() {
        // 1
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        // 2
        while activeSlicePoints.count > 12 {
            activeSlicePoints.removeAtIndex(0)
        }
        
        // 3
        let path = UIBezierPath()
        path.moveToPoint(activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLineToPoint(activeSlicePoints[i])
        }
        
        // 4
        activeSliceBG.path = path.CGPath
        activeSliceFG.path = path.CGPath
    }
    
    /*
     * Function Name: playSwooshSound
     * Parameters: None
     * Purpose: This method randomly plays one of three swoosh sounds.
     * Return Value: None
     */
    
    func playSwooshSound() {
        swooshSoundActive = true
        
        let randomNumber = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        runAction(swooshSound) { [unowned self] in
            self.swooshSoundActive = false
        }
    }
    
    /*
     * Function Name: createEnemy
     * Parameters: forceBomb - whether or not we are forcing enemies to be bombs.
     * Purpose: This method creates an enemy depending on what the forceBomb parameter is.
     *   The enemy created is then randomly placed within the scene and given a random velocity
     *   depending on the enemy's initial position.
     * Return Value: None
     */
    
    func createEnemy(forceBomb forceBomb: ForceBomb = .Default) {
        var enemy: SKSpriteNode
        
        var enemyType = RandomInt(min: 0, max: 6)
        
        // Enemies are always penguins.
        if forceBomb == .Never {
            enemyType = 1
        }
        
        // Enemies are always bombs.
        else if forceBomb == .Always {
            enemyType = 0
        }
        
        // Enemy randomly chosen to be a bomb.
        if enemyType == 0 {
            // 1
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            // 2
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            // 3
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            // 4
            let path = NSBundle.mainBundle().pathForResource("sliceBombFuse.caf", ofType:nil)!
            let url = NSURL(fileURLWithPath: path)
            let sound = try! AVAudioPlayer(contentsOfURL: url)
            bombSoundEffect = sound
            sound.play()
            
            // 5
            let emitter = SKEmitterNode(fileNamed: "sliceFuse")!
            emitter.position = CGPoint(x: 76, y: 64)
            enemy.addChild(emitter)
        }
        
        // Enemy randomly chosen to be a penguin.
        else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            runAction(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        // 1
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        enemy.position = randomPosition
        
        // 2
        let    randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        var randomXVelocity = 0
        
        // 3
        if randomPosition.x < 256 {
            randomXVelocity = RandomInt(min: 8, max: 15)
        } else if randomPosition.x < 512 {
            randomXVelocity = RandomInt(min: 3, max: 5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -RandomInt(min: 3, max: 5)
        } else {
            randomXVelocity = -RandomInt(min: 8, max: 15)
        }
        
        // 4
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        // 5
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody!.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody!.angularVelocity = randomAngularVelocity
        enemy.physicsBody!.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    /*
     * Function Name: tossEnemies
     * Parameters: None
     * Purpose: This method creates tosses enemies onto the screen using the createEnemy method.
     *   The number of enemies, type of enemies, and rate at which the enemies are tossed is
     *   determined by the current sequence position we are at. Once the enemies have been tossed,
     *   the sequence position is updated.
     * Return Value: None
     */
    
    func tossEnemies() {
        if gameEnded {
            return
        }
        
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        // One penguin
        case .OneNoBomb:
            createEnemy(forceBomb: .Never)
            
        // One random enemy
        case .One:
            createEnemy()
            
        // One bomb and one penguin at the same time
        case .TwoWithOneBomb:
            createEnemy(forceBomb: .Never)
            createEnemy(forceBomb: .Always)
        
        // Two random enemies at the same time
        case .Two:
            createEnemy()
            createEnemy()
        
        // Three random enemies at the same time
        case .Three:
            createEnemy()
            createEnemy()
            createEnemy()
        
        // Four random enemies at the same time
        case .Four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()
        
        // A chain of random enemies
        case .Chain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 5.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 4) { [unowned self] in self.createEnemy() }
        
        // A fast chain of random enemies
        case .FastChain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 10.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 4) { [unowned self] in self.createEnemy() }
        }
        
        
        sequencePosition += 1
        
        nextSequenceQueued = false
    }
    
    /*
     * Function Name: subtractLife
     * Parameters: None
     * Purpose: This method subtracts a life from the player and display to the user that they
     *   have lost a life. This method also ends the game when the user has lost a total of three lives
     *   before this method has been currently called.
     * Return Value: None
     */
    
    func subtractLife() {
        lives -= 1
        
        runAction(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        // Two lives left
        if lives == 2 {
            life = livesImages[0]
        }
        // One life left
        else if lives == 1 {
            life = livesImages[1]
        }
        // No lives left
        else {
            life = livesImages[2]
            endGame(triggeredByBomb: false)
        }
        
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        
        life.xScale = 1.3
        life.yScale = 1.3
        life.runAction(SKAction.scaleTo(1, duration:0.1))
    }
    
    /*
     * Function Name: endGame
     * Parameters: triggeredByBomb - whether or not the ending of the game was triggered by a bomb.
     * Purpose: This method ends the game by stopping any user interaction and sounds that were being
     *   played. If the game ending was triggered by a bomb, then all of the user's lives will be cleared
     *   where their lives are displayed.
     * Return Value: None
     */
    
    func endGame(triggeredByBomb triggeredByBomb: Bool) {
        if gameEnded {
            return
        }
        
        gameEnded = true
        physicsWorld.speed = 0
        userInteractionEnabled = false
        
        if bombSoundEffect != nil {
            bombSoundEffect.stop()
            bombSoundEffect = nil
        }
        
        if triggeredByBomb {
            livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
        }
    }
}
