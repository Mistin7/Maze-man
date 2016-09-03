//
//  GameScene.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright (c) 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit
import GameKit
import SystemConfiguration

let Pi = CGFloat(M_PI)

class GameScene: SKScene, GKGameCenterControllerDelegate {
    var playButton = SKSpriteNode(imageNamed: "playButton")
    var leadersButton = SKSpriteNode(imageNamed: "leadersButton")
    var settingsButton = SKSpriteNode(imageNamed: "settingsButton")
    var logo = SKSpriteNode(imageNamed: "logo")
    override func didMove(to view: SKView) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
        
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
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
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
            switch atPoint(location) {
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
        let vc = self.view?.window?.rootViewController
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        vc?.present(gc, animated: true, completion: nil)
    }
    
    //hides leaderboard screen
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController!)
    {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        
    }
}
