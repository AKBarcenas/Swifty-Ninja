//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Alex on 6/21/16.
//  Copyright (c) 2016 Alex Barcenas. All rights reserved.
//

import SpriteKit

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
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
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
     *   Afterwards, the active slice is redrawn and a sound is played if it is active.
     * Return Value: None
     */
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.locationInNode(self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !swooshSoundActive {
            playSwooshSound()
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
}
