//
//  Free.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 08.03.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit

class Free: SKScene {
    var maze: Maze?
    var bgBasic: SKSpriteNode?
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        addBg() //Добавляем самый базовый background
        makeMaze() // Создаём и добавляем лабиринт
    }
    
    func makeMaze() {
        maze = Maze(blockCount: 101, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: 2000, height: 2000), finishBlockI: 17, finishBlockJ: 17, timer: 1, teleports: 2, speedRoads: true, inversions: 1, warders: 1)
        bgBasic!.addChild(maze!.bg!)
        maze!.printMaze()
    }
    
    func addBg() {
        bgBasic = SKSpriteNode(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), size: CGSize(width: CGFloat(2000), height: CGFloat(2000)))
        bgBasic!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgBasic!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(bgBasic!)
    }
}