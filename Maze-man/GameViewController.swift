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
func random(min: CGFloat, max: CGFloat) -> CGFloat {
    assert(min <= max)
    return CGFloat(Float(arc4random()) / Float(UInt32.max)) * (max - min) + min
}

class GameViewController: UIViewController {
    weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingView: UIView! //Для экрана загрузки мультиплеера
    
    var backgroundMusicPlayer: AVAudioPlayer!
    
    var settingsVC: SettingsViewController?
    var competitiveVC: CompetitiveViewController?
    var freeVC: FreeViewController?
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.gameModeOn), name: NSNotification.Name("game mode On"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.gameModeOff), name: NSNotification.Name("game mode Off"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.changedCoinsCount), name: NSNotification.Name("changed coins count"), object: nil)
        
        //Добавляем фоновую музыку
        SKTAudio.sharedInstance().playBackgroundMusic(filename: "sounds/bg-menu-loop.mp3")
        if !defaults.bool(forKey: "sound") {
            SKTAudio.sharedInstance().pauseBackgroundMusic()
        }
        
        settingsVC = SettingsViewController()
        
        self.addChildViewController(settingsVC!)
        scrollView.addSubview(settingsVC!.view)
        settingsVC!.didMove(toParentViewController: self)
        
        //var frameSettings = settingsVC.view.frame
        //var frameSettings = CGRect(origin: CGPoint(x: self.view.frame.size.width, y: 0), size: CGSize(width: settingsVC.view.frame.width, height: settingsVC.view.frame.height))
        //frameSettings.origin.x = self.view.frame.size.width
        //settingsVC.view.frame = frameSettings
        
        
        competitiveVC = CompetitiveViewController()
        
        self.addChildViewController(competitiveVC!)
        scrollView.addSubview(competitiveVC!.view)
        competitiveVC!.didMove(toParentViewController: self)
        
        let frameCompetitive = CGRect(origin: CGPoint(x: self.view.frame.size.width, y: 0), size: CGSize(width: competitiveVC!.view.frame.width, height: competitiveVC!.view.frame.height))
        competitiveVC!.view.frame = frameCompetitive
        
        
        freeVC = FreeViewController()
        
        freeVC!.loadingView = loadingView
        self.addChildViewController(freeVC!)
        scrollView.addSubview(freeVC!.view)
        freeVC!.didMove(toParentViewController: self)
        
        let frameFree = CGRect(origin: CGPoint(x: self.view.frame.size.width * 2, y: 0), size: CGSize(width: freeVC!.view.frame.width, height: freeVC!.view.frame.height))
        freeVC!.view.frame = frameFree
        
        
        scrollView.contentSize = CGSize(width: self.view.frame.size.width * 3, height: self.view.frame.size.height) //Задаём длину нашей прокрутки
        scrollView.contentOffset.x = self.view.frame.size.width //Делаем, чтобы сначала показывался второй экран, а не первый
        //scrollView.contentOffset.x = self.view.frame.size.width * 2 //Делаем, чтобы сначала показывался третий экран, а не первый
        
        //self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: true)
        scrollView.isScrollEnabled = true //Перестаёт перелистывать сцены
        //self.scrollView.directionalLockEnabled = true
        //self.scrollView.canCancelContentTouches = true
        //self.scrollView.delaysContentTouches = true
        //http://stackoverflow.com/questions/31085728/when-programatically-creating-a-viewcontroller-how-can-i-set-its-view-to-be-of/31093001#31093001
        //http://stackoverflow.com/questions/31373244/thread-1-signal-sigabrt-crash-when-casting-uiview-to-skview
        //http://stackoverflow.com/questions/30792196/could-not-cast-value-of-type-uiview-0x112484eb0-to-skview-0x111646718 ?
        //https://www.veasoftware.com/posts/swipe-navigation-in-swift-xcode-7-ios-9-tutorial
        
        /*super.viewDidLoad()
        let skView = self.view as! SKView
        var size = skView.bounds.size
        size.width *= 2
        size.height *= 2
        let scene = GameScene(size: size)
        //let scene = Competitive(size: size)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        scene.scaleMode = .AspectFill
        skView.presentScene(scene)*/
        
        /*switch Int(random(min: 0, max: 2)) {
        case 0: playBackgroundMusic("20_dollars_in_my_pocket.mp3")
        case 1: playBackgroundMusic("pulja_na_vilet.mp3")
        default: break
        }*/
        //playBackgroundMusic("20_dollars_in_my_pocket.mp3")//
                
        authenticateLocalPlayer()
    }
    
    func gameModeOn() {
        scrollView.isScrollEnabled = false //Перестаёт перелистывать сцены
    }
    func gameModeOff() {
        scrollView.isScrollEnabled = true //Перестаёт перелистывать сцены
    }
    func changedCoinsCount() {
        competitiveVC!.scene!.coinsCountLabel.text = "\(competitiveVC!.scene!.defaults.integer(forKey: "coins")) coins"
    }
    
    /*func playBackgroundMusic(_ filename: String) {
        let url = Bundle.main.urlForResource(
            filename, withExtension: nil)
        if (url == nil) {
            print("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        do {
            backgroundMusicPlayer =
                try AVAudioPlayer(contentsOf: url!)
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
    }*/

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    //initiate gamecenter
    func authenticateLocalPlayer() {
        
        let localPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            
            if (viewController != nil) {
                self.present(viewController!, animated: true, completion: nil)
            }
                
            else {
                print((GKLocalPlayer.localPlayer().isAuthenticated))
            }
        }
    }
}
