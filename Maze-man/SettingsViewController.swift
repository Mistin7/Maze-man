//
//  SettingsViewController.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 07.03.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import UIKit
import SpriteKit

class SettingsViewController: UIViewController {
    override func loadView() {
        self.view = SKView(frame: UIScreen.main.applicationFrame)
        //self.view = SKView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 320, height: 640)))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView
        var size = skView.bounds.size
        size.width *= 2
        size.height *= 2
        let scene = Settings(size: size)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        // Do any additional setup after loading the view.
        var label = UILabel(frame: CGRect(x: UIScreen.main.applicationFrame.width / 2 - 315, y: UIScreen.main.applicationFrame.height / 2 - 390, width: 630, height: 850))
        //label.center = CGPoint(x: 100, y: 100)
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont(name: "Chalkboard SE", size: 16)
        label.numberOfLines = 13
        label.text = "- Проходи лабиринты как можно\n быстрее, чтобы получать больше\n опыта и поднимать уровни.\n\n - С уровнями увеличиваются\n лабиринты и появляются\n препятствия.\n\n - Собирай монетки, чтобы\n прокачивать свою скорость.\n\n - И, конечно же, соревнуйся\n с друзьями."
        //label.textColor = UIColor.white
        label.textColor = UIColor(red: 1, green: 157/255, blue: 51/255, alpha: 1.0)
        self.view.addSubview(label)
        
        //Узнаём какие шрифты есть в IOS
        /*for family in UIFont.familyNames {
            print("\(family)")
            
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   \(name)")
            }
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
