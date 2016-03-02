//
//  GameScene.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright (c) 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit
import GameKit

let Pi = CGFloat(M_PI)

class GameScene: SKScene, GKGameCenterControllerDelegate {
    var playButton = SKSpriteNode(imageNamed: "playButton")
    var leadersButton = SKSpriteNode(imageNamed: "leadersButton")
    var settingsButton = SKSpriteNode(imageNamed: "settingsButton")
    var logo = SKSpriteNode(imageNamed: "logo")
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
        
        playButton.size = CGSize(width: 250, height: 110)
        playButton.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(playButton)
        
        settingsButton.size = CGSize(width: 100, height: 100)
        settingsButton.position = CGPoint(x: self.size.width / 2 - 75, y: self.size.height / 2 - 145)
        addChild(settingsButton)
        
        leadersButton.size = CGSize(width: 100, height: 100)
        leadersButton.position = CGPoint(x: self.size.width / 2 + 75, y: self.size.height / 2 - 145)
        addChild(leadersButton)
        
        logo.size = CGSize(width: 268, height: 38)
        logo.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 250)
        addChild(logo)
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            /*if nodeAtPoint(location) == playButton {
                let competitiveScene = Competitive(size: size)
                competitiveScene.scaleMode = scaleMode
                self.view!.presentScene(competitiveScene)
            } else {
                if nodeAtPoint(location) == settingsButton {
                    let settingsScene = Settings(size: size)
                    settingsScene.scaleMode = scaleMode
                    self.view!.presentScene(settingsScene)
                }
            }*/
            switch nodeAtPoint(location) {
            case playButton:
                let competitiveScene = Competitive(size: size)
                competitiveScene.scaleMode = scaleMode
                self.view!.presentScene(competitiveScene)
            case settingsButton:
                let settingsScene = Settings(size: size)
                settingsScene.scaleMode = scaleMode
                self.view!.presentScene(settingsScene)
            case leadersButton:
                showLeader()
            default: break
            }
        }
    }
    
    
    //shows leaderboard screen
    func showLeader() {
        var vc = self.view?.window?.rootViewController
        var gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        vc?.presentViewController(gc, animated: true, completion: nil)
    }
    
    //hides leaderboard screen
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!)
    {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
        
    }
}