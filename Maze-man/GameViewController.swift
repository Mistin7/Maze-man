//
//  GameViewController.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright (c) 2016 Chekunin Alexey. All rights reserved.
//

import UIKit
import SpriteKit

import GameKit
import AVFoundation
func random(min min: CGFloat, max: CGFloat) -> CGFloat {
    assert(min <= max)
    return CGFloat(Float(arc4random()) / Float(UInt32.max)) * (max - min) + min
}

class GameViewController: UIViewController {
    var backgroundMusicPlayer: AVAudioPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = self.view as! SKView
        var size = skView.bounds.size
        size.width *= 2
        size.height *= 2
        let scene = GameScene(size: size)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        scene.scaleMode = .AspectFill
        skView.presentScene(scene)
        
        /*switch Int(random(min: 0, max: 2)) {
        case 0: playBackgroundMusic("20_dollars_in_my_pocket.mp3")
        case 1: playBackgroundMusic("pulja_na_vilet.mp3")
        default: break
        }*/
        //playBackgroundMusic("20_dollars_in_my_pocket.mp3")//
        
        authenticateLocalPlayer()
    }
    
    func playBackgroundMusic(filename: String) {
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        if (url == nil) {
            print("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        do {
            backgroundMusicPlayer =
                try AVAudioPlayer(contentsOfURL: url!)
        } catch let error1 as NSError {
            error = error1
            backgroundMusicPlayer = nil
        }
        if backgroundMusicPlayer == nil {
            print("Could not create audio player: \(error!)")
            return
        }
        
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    //initiate gamecenter
    func authenticateLocalPlayer() {
        
        var localPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            
            if (viewController != nil) {
                self.presentViewController(viewController!, animated: true, completion: nil)
            }
                
            else {
                print((GKLocalPlayer.localPlayer().authenticated))
            }
        }
    }
}
