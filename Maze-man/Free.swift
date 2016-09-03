//
//  Free.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 08.03.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit
import GameKit
import SystemConfiguration
import UIKit

class Free: SKScene {
    var maze: Maze?
    var bgBasic: SKSpriteNode?
    var exitButton: SKSpriteNode? //Поменять на картинку паузы
    
    var oldFingerPosition: CGPoint? = nil
    var resolution: Bool = false
    
    var lastUpdateTime: TimeInterval = 0.0
    var dt = 0.0
    var stopPlaying = true
    
    //То что будет поверх всего перед началом игры
    //var upperLayer = SKSpriteNode()
    var upperLayer: SKShapeNode?
    var logo = SKSpriteNode(imageNamed: "logo")
    var nameMode = SKLabelNode(text: "Free mode")
    var playButton = SKSpriteNode(imageNamed: "playButton")
    
    //То что после раунда мультиплеера
    var winnerBg: SKSpriteNode?
    var playMoreButton = SKSpriteNode(imageNamed: "playButton2")
    var rivalName: String?
    var iAmWinner: Bool? = false //Не забывать обнулять некоторые значения при новой игре (в том числе и iAmWinner, перед началом новой игры, делать его значение false)
    
    var match: GKMatch?
    var iAmHost: Bool = false //Наш телефон сервер или нет
    var rivalWantPlayMore: Bool?
    var iWantPlayMore: Bool = false
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        //Убираем следующие 3 строки, так как они нужны после поиска игрока
        //makeMaze() // Создаём и добавляем лабиринт
        //addBg() //Добавляем самый базовый background
        //bgBasic!.addChild(maze!.bg!) //Добавляем на экран лабиринт, ставим тут, так как нам нужны заранее кординаты плеера
        
        //Всё что идёт поверх карты перед началом игры
        var RoundedRectPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 800)), cornerRadius: 18) //Задаём форму закруглёного фона
        //upperLayer = SKSpriteNode(color: UIColor.black().withAlphaComponent(0.0), size: self.size)
        upperLayer = SKShapeNode(path: RoundedRectPath.cgPath, centered:true)
        upperLayer!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        upperLayer!.lineWidth = 0.0
        upperLayer!.fillColor = UIColor.white
        //upperLayer!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        upperLayer!.zPosition = 99
        addChild(upperLayer!)
        
        logo.size = CGSize(width: 268, height: 38)
        logo.position = CGPoint(x: 0, y: 250)
        logo.zPosition = 99
        upperLayer!.addChild(logo)
        
        nameMode.fontColor = UIColor.black
        nameMode.fontSize = 44
        nameMode.fontName = "Tahoma"
        
        nameMode.position = CGPoint(x: 0, y: 170)
        upperLayer!.addChild(nameMode)
        
        
        playButton.size = CGSize(width: 250, height: 110)
        playButton.position = CGPoint(x: 0, y: -150)
        upperLayer!.addChild(playButton)
    }
    
    override func update(_ currentTime: TimeInterval) {
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
            
            if match != nil {
                if maze!.moveRivalResolution == false {
                    switch maze!.moveRivalDirection {
                    case 0: maze!.moveRival0(dt)
                    case 1: maze!.moveRival1(dt)
                    case 2: maze!.moveRival2(dt)
                    case 3: maze!.moveRival3(dt)
                    default: break
                    }
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
                        //Отправляем сопернику наши координаты (чтобы при задержке Интернета всё отображалось норм)
                        do {
                            try match!.sendData(toAllPlayers: NSData(bytes: [4, UInt8(maze!.playerPosition.i), UInt8(maze!.playerPosition.j)] as [UInt8], length: 3) as Data, with: GKMatchSendDataMode.reliable)
                        } catch {
                            print("Some error in sendData")
                        }
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    //bgBasic!.position.y -= maze!.playerSpeed! * CGFloat(dt) * maze!.kSpeed
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height + size.height / 2 - 10 { //Когда ы у краёв лабиринта, чтобы лабиринт не отходил от краёв экрана (-10 чтобы внизу земля была видна)
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
                        //Отправляем сопернику наши координаты (чтобы при задержке Интернета всё отображалось норм)
                        do {
                            try match!.sendData(toAllPlayers: NSData(bytes: [4, UInt8(maze!.playerPosition.i), UInt8(maze!.playerPosition.j)] as [UInt8], length: 3) as Data, with: GKMatchSendDataMode.reliable)
                        } catch {
                            print("Some error in sendData")
                        }
                        //print(maze!.playerPosition)
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
                        //Отправляем сопернику наши координаты (чтобы при задержке Интернета всё отображалось норм)
                        do {
                            try match!.sendData(toAllPlayers: NSData(bytes: [4, UInt8(maze!.playerPosition.i), UInt8(maze!.playerPosition.j)] as [UInt8], length: 3) as Data, with: GKMatchSendDataMode.reliable)
                        } catch {
                            print("Some error in sendData")
                        }
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height + size.height / 2 - 10{
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
                        //Отправляем сопернику наши координаты (чтобы при задержке Интернета всё отображалось норм)
                        do {
                            try match!.sendData(toAllPlayers: NSData(bytes: [4, UInt8(maze!.playerPosition.i), UInt8(maze!.playerPosition.j)] as [UInt8], length: 3) as Data, with: GKMatchSendDataMode.reliable)
                        } catch {
                            print("Some error in sendData")
                        }
                        //print(maze!.playerPosition)
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
                //Как только наступили на финиш
                if maze!.maze![maze!.playerPosition.i][maze!.playerPosition.j] == 19 {
                    iAmWinner = true
                    if maze!.player!.position == maze!.finishBlock!.position {
                        weOnFinish()
                    }
                }
            }
            
            //Для плеера соперника
            if maze!.moveRivalResolution == false {
                switch maze!.moveRivalDirection {
                case 0: // Вверх
                    if maze!.rivalPlayer!.position.y >= maze!.willRivalPosition!.y {
                        maze!.rivalPlayer!.position.y = -CGFloat(maze!.rivalPosition!.i) * maze!.blockSize!.height - maze!.rivalPlayer!.frame.height / 2
                        maze!.moveRivalDirection = 4
                        maze!.moveRivalResolution = true
                        //maze!.stopPlayerAnimation()
                        if maze!.willRivalDirection != nil {
                            maze!.moveRival(maze!.willRivalDirection!, playerSpeadChange: true)
                            maze!.willRivalDirection = nil
                        }
                    }
                case 1:
                    if maze!.rivalPlayer!.position.x >= maze!.willRivalPosition!.x {
                        maze!.rivalPlayer!.position.x = CGFloat(maze!.rivalPosition!.j) * maze!.blockSize!.width + maze!.rivalPlayer!.frame.width / 2
                        maze!.moveRivalDirection = 4
                        maze!.moveRivalResolution = true
                        //maze!.stopPlayerAnimation()
                        if maze!.willRivalDirection != nil {
                            maze!.moveRival(maze!.willRivalDirection!, playerSpeadChange: true)
                            maze!.willRivalDirection = nil
                        }
                    }
                case 2:
                    if maze!.rivalPlayer!.position.y <= maze!.willRivalPosition!.y {
                        maze!.rivalPlayer!.position.y = -CGFloat(maze!.rivalPosition!.i) * maze!.blockSize!.height - maze!.rivalPlayer!.frame.height / 2
                        maze!.moveRivalDirection = 4
                        maze!.moveRivalResolution = true
                        //maze!.stopPlayerAnimation()
                        if maze!.willRivalDirection != nil {
                            maze!.moveRival(maze!.willRivalDirection!, playerSpeadChange: true)
                            maze!.willRivalDirection = nil
                        }
                    }
                case 3:
                    if maze!.rivalPlayer!.position.x <= maze!.willRivalPosition!.x {
                        maze!.rivalPlayer!.position.x = CGFloat(maze!.rivalPosition!.j) * maze!.blockSize!.width + maze!.rivalPlayer!.frame.width / 2
                        maze!.moveRivalDirection = 4
                        maze!.moveRivalResolution = true
                        //maze!.stopPlayerAnimation()
                        if maze!.willRivalDirection != nil {
                            maze!.moveRival(maze!.willRivalDirection!, playerSpeadChange: true)
                            maze!.willRivalDirection = nil
                        }
                    }
                default: break
                }
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            switch atPoint(location) {
            case playButton:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "mult player"), object: self)
            case exitButton!: break
                //При нажатии на эту кнопку должно поялвяться окно с уточнением
                /*if stopPlaying {
                    stopPlaying = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                } else {
                    stopPlaying = true
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
                }*/
            case playMoreButton:
                print("Хочу ещё сыграть (с тем же)")
                iWantPlayMore = true
                iAmWinner = false
                if rivalWantPlayMore == true { //Если соперник уже тоже хочет
                    //Даём знать что я тоже готов играть ещё
                    do {
                        try match!.sendData(toAllPlayers: NSData(bytes: [6] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                    } catch {
                        print("Some error in sendData")
                    }
                    if iAmHost {
                        forBestHost()
                    }
                    //oneMoreMatch()
                } else if rivalWantPlayMore == false { //Если соперник не хочет то конец
                    //Тут заканчиваем игру с тем плеером так как он больше не будет и выводим на главный экран
                } else if rivalWantPlayMore == nil { //Если соперник ещё не решил, отправляем ему запрос
                    //Здесь должен отправлять запрос на подтверждение ещё одной игры второму парню
                    do {
                        try match!.sendData(toAllPlayers: NSData(bytes: [6] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                    } catch {
                        print("Some error in sendData")
                    }
                    print("Запрос на ещё одну игру отправлен")
                    print("Ждём подтверждения второго игрока")
                }
                //Если мне приходит запрос, то у меня пишется, что-то типа "Тот чувак хочет ещё с вами сыграть, не хотите?"
                //Или типа тот чувак ушёл (ливнул) и кнопка playMoreButton не активна
                //Потом хост игры строит новый лабиринт и отправляет второму и т.д.
            default:
                oldFingerPosition = location
                resolution = true
            }
        }
    }
    
    //func printFriends(friendPlayers: [GKPlayer]?, Error: NSError?) -> Void {
    func printFriends(_ friendPlayers: [GKPlayer]?, _ Error: Error?) {
        for player in friendPlayers! {
            print(player.displayName)
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            var dtLine: CGPoint? = nil
            if resolution == true {
                if oldFingerPosition != nil {
                    dtLine = CGPoint(x: location.x - oldFingerPosition!.x, y: location.y - oldFingerPosition!.y)
                    if dtLine!.y > dtLine!.x && dtLine!.y > -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(0, playerSpeadChange: true)
                            //Отправляем сопернику, что наш плеер должен двигаться вверх прям щас
                            do {
                                try match!.sendData(toAllPlayers: NSData(bytes: [0] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                            } catch {
                                print("Some error in sendData")
                            }
                        } /*else if maze!.moveResolution == false && maze!.willPlayerPosition.y < maze!.player!.position.y { //Это условие никогда не срабатывает
                            maze!.movePlayer(0, playerSpeadChange: false)
                        }*/ else {
                            maze!.willPlayerDirection = 0
                        }
                    } else if dtLine!.y < dtLine!.x && dtLine!.y > -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(1, playerSpeadChange: true)
                            do {
                                try match!.sendData(toAllPlayers: NSData(bytes: [1] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                            } catch {
                                print("Some error in sendData")
                            }
                        } /*else if maze!.moveResolution == false && (maze!.willPlayerPosition.x < maze!.player!.position.x) { //Это условие никогда не срабатывает
                            maze!.movePlayer(1, playerSpeadChange: false)
                        }*/ else {
                            maze!.willPlayerDirection = 1
                        }
                    } else if dtLine!.y < dtLine!.x && dtLine!.y < -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(2, playerSpeadChange: true)
                            do {
                                try match!.sendData(toAllPlayers: NSData(bytes: [2] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                            } catch {
                                print("Some error in sendData")
                            }
                        } /*else if maze!.moveResolution == false && maze!.willPlayerPosition.y > maze!.player!.position.y { //Это условие никогда не срабатывает
                            maze!.movePlayer(2, playerSpeadChange: false)
                        }*/ else {
                            maze!.willPlayerDirection = 2
                        }
                    } else if dtLine!.y > dtLine!.x && dtLine!.y < -dtLine!.x {
                        if maze!.moveResolution == true {
                            maze!.movePlayer(3, playerSpeadChange: true)
                            do {
                                try match!.sendData(toAllPlayers: NSData(bytes: [3] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                            } catch {
                                print("Some error in sendData")
                            }
                        } /*else if maze!.moveResolution == false && maze!.willPlayerPosition.x > maze!.player!.position.x { //Это условие никогда не срабатывает
                            maze!.movePlayer(3, playerSpeadChange: false)
                        }*/ else {
                            maze!.willPlayerDirection = 3
                        }
                    }
                }
                
                resolution = false
            }
        }
    }
    
    func weOnFinish() {
        print("We on FINISH!")
        rivalWantPlayMore = nil //Обнуляем данные
        iWantPlayMore = false
        stopPlaying = true //Останавливаем игру, мы же на финише)
        //Отправляем сопернику, что мы на финише
        do {
            try self.match!.sendData(toAllPlayers: NSData(bytes: [5] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
        } catch {
            print("Some error in sendData")
        }
        winnerBg?.removeFromParent() //Удаляем весь этот фон, так как потом мы его снова добавляем
        addWinnerBg()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
    }
    
    func makeMaze() {
        maze = Maze(competitiveMod: false, blockCount: 31, startBlockI: 1, startBlockJ: 1, finishBlockI: 29, finishBlockJ: 29, timer: 1, speedRoads: false, teleports: 2, inversions: 1, warders: 1, match: match)
        //maze!.printMaze()
    }
    
    func addBg() {
        bgBasic = SKSpriteNode(color: UIColor(red: 25, green: 0, blue: 0, alpha: 1), size: CGSize(width: CGFloat(31 * 30), height: CGFloat(31 * 30)))
        //bgBasic!.position = CGPoint(x: size.width / 2 + maze!.bg!.size.width / 2 - maze!.player!.position.x, y: size.height / 2 + maze!.bg!.size.height / 2 - (maze!.bg!.size.height + maze!.player!.position.y))
        //bgBasic!.position = CGPoint(x: maze!.bg!.size.width / 2, y: size.height - maze!.bg!.size.height / 2)
        bgBasic!.position = CGPoint(x: 0, y: size.height)
        //bgBasic!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bgBasic!.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        addChild(bgBasic!)
        
        exitButton = SKSpriteNode(imageNamed: "close")
        exitButton!.size = CGSize(width: 60, height: 60)
        exitButton!.position = CGPoint(x: size.width - 80, y: size.height - 60)
        exitButton!.zPosition = 99
        bgBasic!.addChild(exitButton!)
    }
    
    func addWinnerBg() {
        winnerBg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: self.size)
        winnerBg!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        winnerBg!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        winnerBg!.zPosition = 99
        addChild(winnerBg!)
        winnerBg!.isHidden = false
        
        var winnerLabel = SKLabelNode(fontNamed: "San Francisco")
        winnerLabel.text = "победил"
        winnerLabel.fontColor = SKColor.white
        winnerLabel.fontSize = 50.0
        winnerLabel.position = CGPoint(x: 0, y: 300)
        winnerBg!.addChild(winnerLabel)
        
        var winnerNameLabel = SKLabelNode(fontNamed: "San Francisco")
        if iAmWinner! {
            winnerNameLabel.text = String(GKLocalPlayer.localPlayer().displayName!)
        } else {
            winnerNameLabel.text = String(rivalName!)
        }
        winnerNameLabel.position = CGPoint(x: 0, y: 250)
        winnerNameLabel.fontColor = SKColor.white
        winnerNameLabel.fontSize = 90.0
        winnerNameLabel.position = CGPoint(x: 0, y: 80)
        winnerBg!.addChild(winnerNameLabel)
        
        playMoreButton.position = CGPoint(x: 0, y: -200)
        winnerBg!.addChild(playMoreButton)
        //Если нажимаем на эту кнопку, то мы хотим сыграть ещё раз с тем же парнем.
        //Кидается запрос и второй чувак должен его принять (подтвердить)
        //Короче, они оба должны нажать на эту кнопку.
        //Если один чувак вышел, то эта кнопка становится неактивной (потемнее)
    }
    
    //Когда мы хотим сыграть ещё раз с тем же плеером
    /*func oneMoreMatch() {
        //Тут генерируем новый лабиринт и т.д., короче, играем заного
        maze!.bg!.removeFromParent()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
        if iAmHost {
            //Отправляем массив с лабиринтом второму плееру
            makeMaze(self.match!)
            maze!.generateMaze()
            var mazeArray: [UInt8] = []
            //Дмумерный массив лабиринта объединяем в одинарный
            for i in maze!.maze! {
                mazeArray += i
            }
            do {
                try self.match!.sendData(toAllPlayers: NSData(bytes: &mazeArray, length: mazeArray.count) as Data, with: GKMatchSendDataMode.reliable)
            } catch {
                print("Some error in sendData")
            }
            print("Массив с лабиринтом отправлен")
            print("Лабиринт построен")
            maze!.startForMultiGame()
            addBg()
            bgBasic!.addChild(maze!.bg!)
            
            winnerBg!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                self.winnerBg!.isHidden = true
                self.stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            })]))
        }
    }*/
    
    
    
    func forBestHost() {
        /*if maze?.bg != nil {
            maze!.bg!.removeFromParent()
        }*/
        maze?.bg?.removeFromParent()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
        
        //Генерируем лабиринт
        /*if maze == nil {
            makeMaze()
        }*/
        makeMaze()
        maze!.generateMaze()
        var mazeArray: [UInt8] = []
        //Дмумерный массив лабиринта объединяем в одинарный
        for i in maze!.maze! {
            mazeArray += i
        }
        //Отправляем массив с лабиринтом сопернику
        do {
            try self.match!.sendData(toAllPlayers: NSData(bytes: &mazeArray, length: mazeArray.count) as Data, with: GKMatchSendDataMode.reliable)
        } catch {
            print("Some error in sendData")
        }
        print("Массив с лабиринтом отправлен")
        //Когда второй раз решаем сыграть надо чтобы haveMaze снова стал true
        print("Лабиринт построен")
        maze!.startForMultiGame() //Отправляем свой скин и скорость сопернику, также прорисоываем у себя лабиринт
        if bgBasic == nil {
            addBg()
        } else { bgBasic!.position = CGPoint(x: 0, y: size.height) }
        bgBasic!.addChild(maze!.bg!)
        if upperLayer!.isHidden == false {
            upperLayer!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                self.upperLayer!.isHidden = true
                self.stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            })]))
        } else if winnerBg?.isHidden == false {
            winnerBg?.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -self.size.height), duration: 0.6), SKAction.run({
                self.winnerBg?.isHidden = true
                self.stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            })]))
        }
    }
    
}

//Баг:
//- когда мы медленно двигаем пальцем в правом окне (мультиплеере), тогда выходил ошибка что найден nil
// - Когда не удалось определить сервер и делает это рандом, почему то на устройствах отобразились разные лабиринты !!!

//Когда оба плеера ожидают начала игры, должен отображаться экран загрузки, а не стартовый экран с кнопкой Play
