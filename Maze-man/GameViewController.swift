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
        
        scrollView.isScrollEnabled = true //Перестаёт перелистывать сцены
                
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
