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
    
    var oldFingerPosition: CGPoint? = nil
    var resolution: Bool = false
    
    var lastUpdateTime: NSTimeInterval = 0.0
    var dt = 0.0
    var stopPlaying = false
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        makeMaze() // Создаём и добавляем лабиринт
        addBg() //Добавляем самый базовый background
        bgBasic!.addChild(maze!.bg!) //Добавляем на экран лабиринт, ставим тут, так как нам нужны заранее кординаты плеера
    }
    
    override func update(currentTime: NSTimeInterval) {
        if !stopPlaying {
            if lastUpdateTime > 0 { dt = currentTime - lastUpdateTime } else {dt = 0 }
            lastUpdateTime = currentTime
            
            if maze!.speedTimer > 0 {
                maze!.speedTimer -= dt
                if maze!.speedTimer <= 0 {
                    maze!.endUseSpeedRoad()
                }
            }
            
            if maze!.moveResolution == false {
                switch maze!.movePlayerDirection {
                case 0: maze!.movePlayer0(dt)
                case 1: maze!.movePlayer1(dt)
                case 2: maze!.movePlayer2(dt)
                case 3: maze!.movePlayer3(dt)
                default: break
                }
            }
            
            //Если столкнулись со смотрителем, то мы проиграли
            /*if maze!.checkCollisions() {
             weLosed()
             }*/
            //Проверяем на столкновение (смотрели, монетки)
            switch maze!.checkCollisions() {
            case 0: break
            default: break
            }
            
        }
    }
    override func didFinishUpdate() {
        if !stopPlaying {
            if maze!.moveResolution == false {
                switch maze!.movePlayerDirection {
                case 0: // Вверх
                    if maze!.player!.position.y >= maze!.willPlayerPosition.y {
                        //maze!.player!.position.y = maze!.willPlayerPosition.y
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    //bgBasic!.position.y -= maze!.playerSpeed! * CGFloat(dt) * maze!.kSpeed
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height - size.height / 2 { //Когда ы у краёв лабиринта, чтобы лабиринт не отходил от краёв экрана
                        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
                        bgBasic!.position.y = size.height / 2 - maze!.player!.position.y
                    }
                case 1:
                    if maze!.player!.position.x >= maze!.willPlayerPosition.x {
                        //maze!.player!.position.x = maze!.willPlayerPosition.x
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    //bgBasic!.position.x -= maze!.playerSpeed! * CGFloat(dt) * maze!.kSpeed
                    if maze!.player!.position.x > size.width / 2 && maze!.player!.position.x < maze!.bg!.frame.width - size.width / 2 {
                        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
                        bgBasic!.position.x = -maze!.player!.position.x + size.width / 2
                    }
                case 2:
                    if maze!.player!.position.y <= maze!.willPlayerPosition.y {
                        //maze!.player!.position.y = maze!.willPlayerPosition.y
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height - size.height / 2 {
                        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
                        bgBasic!.position.y = size.height / 2 - maze!.player!.position.y
                    }
                case 3:
                    if maze!.player!.position.x <= maze!.willPlayerPosition.x {
                        //maze!.player!.position.x = maze!.willPlayerPosition.x
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    if maze!.player!.position.x > size.width / 2 && maze!.player!.position.x < maze!.bg!.frame.width - size.width / 2 {
                        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
                        bgBasic!.position.x = -maze!.player!.position.x + size.width / 2
                    }
                default: break
                }
            }
            print("ЙЦУ ", maze!.player!.position)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            switch nodeAtPoint(location) {
            default:
                oldFingerPosition = location
                resolution = true
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            var dtLine: CGPoint? = nil
            if resolution == true {
                if oldFingerPosition != nil {
                    dtLine = CGPoint(x: location.x - oldFingerPosition!.x, y: location.y - oldFingerPosition!.y)
                    if dtLine!.y > dtLine!.x && dtLine!.y > -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(0, playerSpeadChange: true)
                        } else if maze!.moveResolution == false && maze!.willPlayerPosition.y < maze!.player!.position.y {
                            maze!.movePlayer(0, playerSpeadChange: false)
                        } else {
                            maze!.willPlayerDirection = 0
                        }
                    } else if dtLine!.y < dtLine!.x && dtLine!.y > -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(1, playerSpeadChange: true)
                        } else if maze!.moveResolution == false && (maze!.willPlayerPosition.x < maze!.player!.position.x) {
                            maze!.movePlayer(1, playerSpeadChange: false)
                        } else {
                            maze!.willPlayerDirection = 1
                        }
                    } else if dtLine!.y < dtLine!.x && dtLine!.y < -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(2, playerSpeadChange: true)
                        } else if maze!.moveResolution == false && maze!.willPlayerPosition.y > maze!.player!.position.y {
                            maze!.movePlayer(2, playerSpeadChange: false)
                        } else {
                            maze!.willPlayerDirection = 2
                        }
                    } else if dtLine!.y > dtLine!.x && dtLine!.y < -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(3, playerSpeadChange: true)
                        } else if maze!.moveResolution == false && maze!.willPlayerPosition.x > maze!.player!.position.x {
                            maze!.movePlayer(3, playerSpeadChange: false)
                        } else {
                            maze!.willPlayerDirection = 3
                        }
                    }
                }
                
                resolution = false
            }
        }
    }
    
    func makeMaze() {
        maze = Maze(competitiveMod: false, blockCount: 61, startBlockI: 1, startBlockJ: 1, finishBlockI: 13, finishBlockJ: 13, timer: 1, teleports: 2, speedRoads: false, inversions: 1, warders: 1)
        maze!.printMaze()
    }
    
    func addBg() {
        bgBasic = SKSpriteNode(color: UIColor(red: 25, green: 0, blue: 0, alpha: 1), size: CGSize(width: CGFloat(31 * 30), height: CGFloat(31 * 30)))
        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
        //bgBasic!.position = CGPoint(x: maze!.bg!.size.width / 2, y: size.height - maze!.bg!.size.height / 2)
        bgBasic!.position = CGPoint(x: 0, y: size.height)
        //bgBasic!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bgBasic!.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        addChild(bgBasic!)
    }
}