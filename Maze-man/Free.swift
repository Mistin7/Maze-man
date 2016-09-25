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
    var exitButton = SKSpriteNode(imageNamed: "close") //Поменять на картинку паузы
    
    var oldFingerPosition: CGPoint? = nil
    var resolution: Bool = false
    
    var lastUpdateTime: TimeInterval = 0.0
    var dt = 0.0
    var stopPlaying = true
    
    //То что будет поверх всего перед началом игры
    var upperLayer: SKShapeNode?
    var logo = SKSpriteNode(imageNamed: "logo")
    var nameMode = SKLabelNode(text: "Мультиплеер")
    var playButton = SKSpriteNode(imageNamed: "playButton")
    
    //То что после раунда мультиплеера
    var winnerBg: SKSpriteNode?
    var playMoreButton = SKSpriteNode(imageNamed: "playButton2")
    var rivalName: String?
    var iAmWinner: Bool? = false //Не забывать обнулять некоторые значения при новой игре (в том числе и iAmWinner, перед началом новой игры, делать его значение false)
    var winnerNameLabel: SKLabelNode? //Показываем имя победителя (надо было вынести из блока addWinnerBg для доступа в showWinnerBg)
    var infoLabel: SKLabelNode?
    
    var match: GKMatch?
    var iAmHost: Bool = false //Наш телефон сервер или нет
    var rivalWantPlayMore: Bool?
    var iWantPlayMore: Bool = false
    var iLeft: Bool = false //Чтобы опрелить отключился я или cоперник
    
    let defaults = UserDefaults.standard
    
    //Различная озвучка
    var clickSound: SKAction?
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        //Всё что идёт поверх карты перед началом игры
        var RoundedRectPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 800)), cornerRadius: 18) //Задаём форму закруглёного фона
        upperLayer = SKShapeNode(path: RoundedRectPath.cgPath, centered:true)
        upperLayer!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        upperLayer!.lineWidth = 0.0
        upperLayer!.fillColor = UIColor.white
        upperLayer!.zPosition = 99
        addChild(upperLayer!)
        
        logo.size = CGSize(width: 268, height: 38)
        logo.position = CGPoint(x: 0, y: 250)
        logo.zPosition = 99
        upperLayer!.addChild(logo)
        
        nameMode.fontColor = UIColor.black
        nameMode.fontSize = 34
        nameMode.fontName = "Tahoma"
        
        nameMode.position = CGPoint(x: 0, y: 170)
        upperLayer!.addChild(nameMode)
        
        
        playButton.size = CGSize(width: 250, height: 110)
        playButton.position = CGPoint(x: 0, y: -150)
        upperLayer!.addChild(playButton)
        
        //Добавляем различную озвучку
        clickSound = SKAction.playSoundFileNamed("sounds/click.mp3", waitForCompletion: false)
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
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    //bgBasic!.position.y -= maze!.playerSpeed! * CGFloat(dt) * maze!.kSpeed
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height + size.height / 2 - 10 { //Когда ы у краёв лабиринта, чтобы лабиринт не отходил от краёв экрана (-10 чтобы внизу земля была видна)
                        bgBasic!.position.y = size.height / 2 - maze!.player!.position.y
                    }
                case 1:
                    if maze!.player!.position.x >= maze!.willPlayerPosition.x {
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
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    //bgBasic!.position.x -= maze!.playerSpeed! * CGFloat(dt) * maze!.kSpeed
                    if maze!.player!.position.x > size.width / 2 && maze!.player!.position.x < maze!.bg!.frame.width - size.width / 2 {
                        bgBasic!.position.x = -maze!.player!.position.x + size.width / 2
                    }
                case 2:
                    if maze!.player!.position.y <= maze!.willPlayerPosition.y {
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
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    if maze!.player!.position.y < -size.height / 2 && maze!.player!.position.y > -maze!.bg!.frame.height + size.height / 2 - 10{
                        bgBasic!.position.y = size.height / 2 - maze!.player!.position.y
                    }
                case 3:
                    if maze!.player!.position.x <= maze!.willPlayerPosition.x {
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
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                    if maze!.player!.position.x > size.width / 2 && maze!.player!.position.x < maze!.bg!.frame.width - size.width / 2 {
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
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "mult player"), object: self)
            case exitButton:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                if match!.players.count != 0 { //Если я хочу ливнуть (соперник ещё не ливнул)
                    iLeft = true
                    match!.disconnect()
                    resolution = false
                    stopPlaying = true
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
                } else { //Если соперник уже ливнул
                    match!.disconnect()
                    upperLayer!.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height / 2)
                    upperLayer!.isHidden = false
                    bgBasic?.removeFromParent()
                    exitButton.isHidden = true
                    resolution = false
                    hideWinnerBg()
                    stopPlaying = true
                }
                //При нажатии на эту кнопку должно поялвяться окно с уточнением
            case playMoreButton:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                //чтобы я мог только один раз нажать на эту кнопку
                if match!.players.count == 0 {
                    print("Соперник отключился, мы не можем больше с ним сыграть")
                } else {
                    if !iWantPlayMore  {
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
                        } else if rivalWantPlayMore == false { //Если соперник не хочет то конец
                            //Тут заканчиваем игру с тем плеером так как он больше не будет и выводим на главный экран
                            infoLabel!.isHidden = false
                            infoLabel!.text = self.match!.players[0].displayName! + " покинул игру."
                            infoLabel!.fontColor = UIColor.red
                        } else if rivalWantPlayMore == nil { //Если соперник ещё не решил, отправляем ему запрос
                            //Здесь должен отправлять запрос на подтверждение ещё одной игры второму парню
                            do {
                                try match!.sendData(toAllPlayers: NSData(bytes: [6] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
                            } catch {
                                print("Some error in sendData")
                            }
                            print("Запрос на ещё одну игру отправлен")
                            print("Ждём подтверждения второго игрока")
                            infoLabel!.isHidden = false
                            infoLabel!.text = "Запрос отправлен. Ждём ответа " + self.match!.players[0].displayName! + "."
                            infoLabel!.fontColor = UIColor.gray
                        }
                    }
                }
            default:
                oldFingerPosition = location
                resolution = true
            }
        }
    }
    
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
                        } else {
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
                        } else {
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
                        } else {
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
                        }  else {
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
        showWinnerBg()
    }
    
    func makeMaze() {
        maze = Maze(competitiveMod: false, blockCount: 31, startBlockI: 1, startBlockJ: 1, finishBlockI: 29, finishBlockJ: 29, timer: 1, speedRoads: false, teleports: 2, inversions: 1, warders: 1, match: match)
    }
    
    func addBg() {
        bgBasic = SKSpriteNode(color: UIColor(red: 25, green: 0, blue: 0, alpha: 1), size: CGSize(width: CGFloat(31 * 30), height: CGFloat(31 * 30)))
        bgBasic!.position = CGPoint(x: 0, y: size.height)
        bgBasic!.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        addChild(bgBasic!)
        
        exitButton.size = CGSize(width: 60, height: 60)
        exitButton.position = CGPoint(x: size.width - 80, y: size.height - 60)
        exitButton.zPosition = 100
        if exitButton.parent == nil {
            addChild(exitButton)
        }
    }
    
    func addWinnerBg() {
        winnerBg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: self.size)
        winnerBg!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        winnerBg!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        winnerBg!.zPosition = 99
        addChild(winnerBg!)
        winnerBg!.isHidden = true
        
        var winnerLabel = SKLabelNode(fontNamed: "San Francisco")
        winnerLabel.text = "победил"
        winnerLabel.fontColor = SKColor.white
        winnerLabel.fontSize = 50.0
        winnerLabel.position = CGPoint(x: 0, y: 300)
        winnerBg!.addChild(winnerLabel)
        
        winnerNameLabel = SKLabelNode(fontNamed: "San Francisco")
        winnerNameLabel!.fontColor = SKColor.white
        winnerNameLabel!.fontSize = 90.0
        winnerNameLabel!.position = CGPoint(x: 0, y: 80)
        winnerBg!.addChild(winnerNameLabel!)
        
        playMoreButton.position = CGPoint(x: 0, y: -200)
        playMoreButton.size = CGSize(width: 397, height: 136)
        playMoreButton.alpha = 1.0
        winnerBg!.addChild(playMoreButton)
        
        infoLabel = SKLabelNode(fontNamed: "San Francisco")
        infoLabel!.text = nil
        infoLabel!.fontSize = 24
        infoLabel!.position = CGPoint(x: 0, y: -40)
        winnerBg!.addChild(infoLabel!)
    }
    
    func showWinnerBg() {
        if winnerBg?.isHidden == true || winnerBg == nil || winnerBg?.parent == nil {
            winnerBg?.isHidden = false
            if winnerBg == nil { //Если мы ещё не добавляли эти спрайты, то добвим сейчас
                addWinnerBg()
            } else if winnerBg?.parent == nil {
                addChild(winnerBg!)
            }
            
            //Тут настраиваем имя победителя
            if iAmWinner! {
                winnerNameLabel!.text = String(GKLocalPlayer.localPlayer().displayName!)
            } else {
                winnerNameLabel!.text = String(rivalName!)
            }
            
            winnerBg!.isHidden = false
            winnerBg!.position = CGPoint(x: size.width / 2, y: size.height / 2)
            
            //Останавливаем процесс игры и разрешаем промотку по view
            stopPlaying = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
        }
    }
    
    func hideWinnerBg() {
        winnerBg?.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
            self.winnerBg?.isHidden = true
            self.stopPlaying = false
            if self.match!.players.count != 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            }
        })]))
    }
    

    
    
    func forBestHost() {
        maze?.bg?.removeFromParent()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
        
        //Генерируем лабиринт
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
                self.exitButton.isHidden = false
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

