//
//  Settings.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit

class Settings: SKScene {
    var soundButton = SKSpriteNode(imageNamed: "soundOn")
    var backButton = SKSpriteNode(imageNamed: "backButton")
    let defaults = NSUserDefaults.standardUserDefaults()
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
        
        if defaults.boolForKey("sound") { soundButton.texture = SKTexture(imageNamed: "soundOff") }
        else { soundButton.texture = SKTexture(imageNamed: "soundOn") }
        soundButton.size = CGSize(width: 50, height: 50)
        soundButton.position = CGPoint(x: self.size.width - soundButton.size.width - 20, y: self.size.height - soundButton.size.height - 20)
        addChild(soundButton)
        
        //Кнопка в главное меню
        backButton.size = CGSize(width: 50, height: 50)
        backButton.position = CGPoint(x: 70, y: size.height - 70)
        addChild(backButton)
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            switch nodeAtPoint(location) {
            case soundButton:
                if defaults.boolForKey("sound") {
                    soundButton.texture = SKTexture(imageNamed: "soundOn")
                    defaults.setBool(false, forKey: "sound")
                } else {
                    soundButton.texture = SKTexture(imageNamed: "soundOff")
                    defaults.setBool(true, forKey: "sound")
                }
            case backButton:
                let gameScene = GameScene(size: size)
                gameScene.scaleMode = scaleMode
                self.view!.presentScene(gameScene)
            default: break
            }
        }
    }
}