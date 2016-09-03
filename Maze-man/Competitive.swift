//
//  Competitive.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit
import GameKit

class Competitive: SKScene, GKGameCenterControllerDelegate {
    //То что будет поверх всего перед началом игры
    //var upperLayer = SKSpriteNode()
    var upperLayer: SKShapeNode?
    var logo = SKSpriteNode(imageNamed: "logo")
    var playButton = SKSpriteNode(imageNamed: "playButton")
    var leadersButton = SKSpriteNode(imageNamed: "leadersButton")
    
    var maze: Maze?
    var bgBasic: SKSpriteNode?
    var oldFingerPosition: CGPoint? = nil
    var resolution: Bool = false
    var restart  = SKSpriteNode(imageNamed: "restart")
    //var backButton = SKSpriteNode(imageNamed: "backButton")
    var lastUpdateTime: TimeInterval = 0.0
    var dt = 0.0
    var stopPlaying = true
    
    //Секундомер
    var count: Double = 0.0
    var timer = Timer()
    var timeLabel = SKLabelNode()
    var bestTimeLabel = SKLabelNode()
    let defaults = UserDefaults.standard
    var results: Double = 0
    
    var coinsCountLabel = SKLabelNode()  //Текст с количеством монет
    
    //Результат после финиша
    var resultBg: SKSpriteNode?
    var continueButton = SKSpriteNode(imageNamed: "playButton2")
    var plusPercent = SKLabelNode(fontNamed: "Myriad Pro")
    var currentLvl = SKLabelNode(fontNamed: "Myriad Pro") //Лвл, на котором мы сейчас
    var nextLvl = SKLabelNode(fontNamed: "Myriad Pro") //Следующий лвл
    var bgLvlLine: SKSpriteNode?
    var lvlLine: SKSpriteNode?
    let cropNode = SKCropNode() //Для отображения полосы уровня
    var lvlLineMask = SKSpriteNode() //Через неё видна полоса лвл-а
    var countLvlUp: Int = 0 //Сколько лвл поднимает пользователь (для progressBar)
    
    //
    var dtWithLvlLine: CGFloat?
    var timeOfLvlLineEvolution: CGFloat?
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
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
        //upperLayer.hidden = true
        
        logo.size = CGSize(width: 268, height: 38)
        logo.position = CGPoint(x: 0, y: 250)
        logo.zPosition = 99
        upperLayer!.addChild(logo)
        
        playButton.size = CGSize(width: 250, height: 110)
        playButton.position = CGPoint(x: 0, y: -150)
        upperLayer!.addChild(playButton)
        
        leadersButton.size = CGSize(width: 100, height: 100)
        leadersButton.position = CGPoint(x: 75, y: -295)
        upperLayer!.addChild(leadersButton)
        
        
        if defaults.integer(forKey: "points") < 100 {
            defaults.set(100, forKey: "points")
        }
        
        //NSNotificationCenter.defaultCenter().postNotificationName("game mode On", object: self)
        
        //backgroundColor = SKColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        addBg() //Добавляем самый базовый background
        makeMaze() // Создаём и добавляем лабиринт
        addTimer() //Добавляем время
        addResult() //Добавляем результаты после прохождения
        //Restart
        restart.size = CGSize(width: 40, height: 40)
        restart.position = CGPoint(x: size.width - 80, y: size.height - 60)
        addChild(restart)
        //Кнопка в главное меню
        //backButton.size = CGSize(width: 50, height: 50)
        //backButton.position = CGPoint(x: 70, y: size.height - 70)
        //addChild(backButton)
        //Добавляем кол-во  монеток на экран
        addCoinsInfo()
        
        //GameViewController.data.scrollView.scrollEnabled = false
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
            
            //Проверяем на столкновение (смотрели, монетки)
            switch maze!.checkCollisions() {
            case 0: break
            case 1: weLosed(); break
            case 2:
                defaults.set(defaults.integer(forKey: "coins") + 1, forKey: "coins")
                coinsCountLabel.text = "\(defaults.integer(forKey: "coins")) coins"
                break
            default: break
            }
            
        } else {
            //print(lvlLineMask.position)
        }
    }
    override func didFinishUpdate() {
        if !stopPlaying {
            if maze!.moveResolution == false {
                switch maze!.movePlayerDirection {
                case 0:
                    if maze!.player!.position.y >= maze!.willPlayerPosition.y {
                        //maze!.player!.position.y = maze!.willPlayerPosition.y
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 1:
                    if maze!.player!.position.x >= maze!.willPlayerPosition.x {
                        //maze!.player!.position.x = maze!.willPlayerPosition.x
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 2:
                    if maze!.player!.position.y <= maze!.willPlayerPosition.y {
                        //maze!.player!.position.y = maze!.willPlayerPosition.y
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 3:
                    if maze!.player!.position.x <= maze!.willPlayerPosition.x {
                        //maze!.player!.position.x = maze!.willPlayerPosition.x
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        //print(maze!.playerPosition)
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                default: break
                }
            }
            //Как только наступили на финиш
            if maze!.maze![maze!.playerPosition.i][maze!.playerPosition.j] == 19 {
                if maze!.player!.position == maze!.finishBlock!.position {
                    weOnFinish()
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            switch atPoint(location) {
            case playButton:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                upperLayer!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -self.size.height), duration: 0.6), SKAction.run({
                    self.upperLayer!.isHidden = true
                    self.stopPlaying = false
                })]))
            case restart:
                maze!.bg!.removeFromParent()
                timer.invalidate()
                makeMaze()
                /*case backButton:
                let gameScene = GameScene(size: size)
                gameScene.scaleMode = scaleMode
                self.view!.presentScene(gameScene)*/
            case continueButton:
                maze!.bg!.removeFromParent()
                stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                resultBg!.isHidden = true
                makeMaze()
            case leadersButton:
                showLeader()
            default:
                oldFingerPosition = location
                resolution = true
            }
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
    func weOnFinish() {
        print("You won")
        timer.invalidate()
        if count < defaults.double(forKey: "bestTime") || defaults.double(forKey: "bestTime") == 0.0 {
            defaults.set(count, forKey: "bestTime")
            results = defaults.double(forKey: "bestTime")
            bestTimeLabel.text = "Best time: \(results)"
        }
        
        countLvlUp = (defaults.integer(forKey: "points") % 100 + Int(350/count)) / 100
        //runAction(SKAction.sequence([SKAction.waitForDuration(1), SKAction.runBlock(showResultBg)]))
        showResultBg(true)
        
        saveHighscore(defaults.integer(forKey: "points") / 100)
    }
    
    func weLosed() {
        print("You losed!")
        timer.invalidate()
        countLvlUp = 0
        showResultBg(false)
    }
    
    func showResultBg(_ win: Bool) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
        stopPlaying = true
        resultBg!.isHidden = false
        lvlLineMask.position.x = -lvlLine!.size.width * 1.5 + CGFloat(defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * lvlLine!.size.width //Как выглядит полоса до прибавки процентов
        currentLvl.text = "\(Int(defaults.integer(forKey: "points") / 100)) lvl"
        nextLvl.text = "\(Int(defaults.integer(forKey: "points") / 100) + 1) lvl"
        
        if win {
            dtWithLvlLine = 3.5 / CGFloat(count) * lvlLine!.size.width
            plusPercent.text = "+\(Int(350/count))%"
        } else {
            dtWithLvlLine = 0
            plusPercent.text = "0%"
        }
        timeOfLvlLineEvolution = 2.0
        
        let dtWithLvlLine2 = dtWithLvlLine! - self.lvlLine!.size.width + CGFloat(self.defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * self.lvlLine!.size.width
        //var dtPoints: CGFloat = CGFloat(3.5/count) //Сколько плеер поднял процентов/100 за раунд
        //Тут остановился
        if countLvlUp == 0 {
            lvlLineMask.run(SKAction.moveBy(x: dtWithLvlLine!, y: 0, duration: 1))
        } else if countLvlUp == 1 {
            lvlLineMask.run(SKAction.sequence([
                SKAction.wait(forDuration: 1),
                SKAction.moveBy(x: lvlLine!.size.width - CGFloat(defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * lvlLine!.size.width, y: 0, duration: 2),
                SKAction.run({
                    self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                    //print(self.dtWithLvlLine!)
                    //self.dtWithLvlLine! = self.dtWithLvlLine! - self.lvlLine!.size.width + CGFloat(self.defaults.integerForKey("points")) % 100 / 100 * self.lvlLine!.size.width
                    print("lvlUp")
                    //print(self.dtWithLvlLine!)
                }),
                SKAction.wait(forDuration: 1),
                //SKAction.moveByX(self.dtWithLvlLine!, y: 0, duration: 2)
                SKAction.moveBy(x: dtWithLvlLine2, y: 0, duration: 2)
                ]))
        } else if countLvlUp > 1 {
            lvlLineMask.run(SKAction.sequence([
                SKAction.wait(forDuration: 1),
                SKAction.moveBy(x: lvlLine!.size.width - CGFloat(defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * lvlLine!.size.width, y: 0, duration: 2),
                SKAction.run({
                    self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                    self.dtWithLvlLine! -= self.lvlLine!.size.width + CGFloat(self.defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * self.lvlLine!.size.width
                }),
                SKAction.repeat(SKAction.sequence([
                    SKAction.moveBy(x: lvlLine!.size.width, y: 0, duration: 2),
                    SKAction.run({
                        self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                        self.dtWithLvlLine! -= self.lvlLine!.size.width
                    })
                    ]), count: countLvlUp - 2),
                SKAction.wait(forDuration: 2),
                SKAction.moveBy(x: self.dtWithLvlLine!, y: 0, duration: 2)
                ]))
        }
        
        defaults.set(defaults.integer(forKey: "points") + (Int(350/count)), forKey: "points")
    }
    
    func makeMaze() {
        switch Int(defaults.integer(forKey: "points") / 100) {
        case 1: maze = Maze(blockCount: 9, mazeSize: CGSize(width: size.width * 0.6, height: size.height * 0.6), finishBlockI: 7, finishBlockJ: 7)
        case 2...3:  maze = Maze(blockCount: 11, mazeSize: CGSize(width: size.width * 0.67, height: size.height * 0.67), finishBlockI: 9, finishBlockJ: 9)
        case 4...5: maze = Maze(blockCount: 11, mazeSize: CGSize(width: size.width * 0.67, height: size.height * 0.67), finishBlockI: 9, finishBlockJ: 9, timer: 1)
        case 6...8: maze = Maze(blockCount: 13, mazeSize: CGSize(width: size.width * 0.72, height: size.height * 0.72), finishBlockI: 11, finishBlockJ: 11, timer: 1)
        case 9...11: maze = Maze(blockCount: 13, mazeSize: CGSize(width: size.width * 0.72, height: size.height * 0.72), finishBlockI: 11, finishBlockJ: 11, timer: 1, speedRoads: true)
        case 12...14: maze = Maze(blockCount: 15, mazeSize: CGSize(width: size.width * 0.8, height: size.height * 0.8), finishBlockI: 13, finishBlockJ: 13, timer: 1, speedRoads: true)
        case 15...17: maze = Maze(blockCount: 17, mazeSize: CGSize(width: size.width * 0.9, height: size.height * 0.9), finishBlockI: 15, finishBlockJ: 15, timer: 1, speedRoads: true)
        case 18...19: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true)
        case 20...24: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 1)
        case 25...27: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2)
        case 28...33: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2, inversions: 1)
        case 34...999: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2, inversions: 1, warders: 1)
        //case 9...999: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2, inversions: 1, warders: 1)
        default: break
        }
        //maze = Maze(blockCount: 19, mazeSize: size, finishBlockI: 17, finishBlockJ: 17)
        //maze!.generateTimer()
        //maze!.addSpeedRoads()
        //maze!.addTeleport(4)
        bgBasic!.addChild(maze!.bg!)
        maze!.printMaze()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Competitive.counter), userInfo: nil, repeats: true)
        count = 0.0
    }
    
    func addResult() {
        resultBg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: self.size)
        resultBg!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resultBg!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        resultBg!.zPosition = 99
        addChild(resultBg!)
        resultBg!.isHidden = true
        
        continueButton.position = CGPoint(x: 0, y: -280)
        resultBg!.addChild(continueButton)
        
        if defaults.integer(forKey: "points") == 0 {
            defaults.set(100, forKey: "points")
        }
        
        plusPercent.position = CGPoint(x: 0, y: 120)
        plusPercent.fontColor = SKColor.white
        plusPercent.fontSize = 120.0
        resultBg!.addChild(plusPercent)
        
        currentLvl.position = CGPoint(x: -240, y: -50)
        currentLvl.fontColor = SKColor.white
        currentLvl.fontSize = 44.0
        resultBg!.addChild(currentLvl)
        
        nextLvl.position = CGPoint(x: 240, y: -50)
        nextLvl.fontColor = SKColor.white
        nextLvl.fontSize = 44.0
        resultBg!.addChild(nextLvl)
        
        bgLvlLine = SKSpriteNode(color: UIColor.white, size: CGSize(width: size.width * 0.8 + 20, height: 60))
        bgLvlLine!.position = CGPoint(x: 0, y: 50)
        resultBg!.addChild(bgLvlLine!)
        
        lvlLine = SKSpriteNode(color: UIColor.black, size: CGSize(width: size.width * 0.8, height: 40))
        
        lvlLineMask = SKSpriteNode(color: UIColor.black, size: CGSize(width: size.width * 0.8, height: 40))
        lvlLineMask.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        lvlLineMask.position = CGPoint(x: -lvlLine!.size.width / 2, y: 0)
        
        cropNode.addChild(lvlLine!)
        cropNode.maskNode = lvlLineMask
        cropNode.position = CGPoint(x: 0, y: 0)
        bgLvlLine!.addChild(cropNode)
    }
    
    func addBg() {
        bgBasic = SKSpriteNode(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), size: CGSize(width: CGFloat(size.width), height: CGFloat(size.width)))
        bgBasic!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgBasic!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(bgBasic!)
    }
    
    func addCoinsInfo() {
        let coinIcon = SKSpriteNode(imageNamed: "coin")
        coinIcon.size = CGSize(width: 50, height: 50)
        coinIcon.position = CGPoint(x: 70, y: 70)
        addChild(coinIcon)
        
        coinsCountLabel.text = "\(defaults.integer(forKey: "coins")) coins"
        coinsCountLabel.position = CGPoint(x: 160, y: 57)
        coinsCountLabel.fontColor = SKColor.white
        coinsCountLabel.fontSize = 34
        coinsCountLabel.fontName = "Chalkboard SE Bold"
        coinsCountLabel.name = "coinsCount"
        coinsCountLabel.zPosition = 99
        addChild(coinsCountLabel)
    }
    
    func addTimer() {
        timeLabel.text = "Time: \(count)"
        timeLabel.position = CGPoint(x: size.width - 80, y: size.height - 160)
        timeLabel.fontColor = SKColor.white
        timeLabel.fontSize = 28
        timeLabel.fontName = "Chalkboard SE Bold"
        timeLabel.name = "timer"
        timeLabel.zPosition = 99
        addChild(timeLabel)
        
        results = defaults.double(forKey: "bestTime")
        bestTimeLabel.text = "Best time: \(results)"
        bestTimeLabel.position = CGPoint(x: 150, y: size.height - 160)
        bestTimeLabel.fontColor = SKColor.white
        bestTimeLabel.fontSize = 28
        bestTimeLabel.fontName = "Chalkboard SE Bold"
        bestTimeLabel.name = "bestTime"
        bestTimeLabel.zPosition = 99
        addChild(bestTimeLabel)
    }
    func counter() {
        if stopPlaying == false {
            //Если не действует заморозка, то
            if maze!.playTimer {
                count += 0.1
                count = round(10 * count) / 10//Округляем до десятых
                timeLabel.text = "Time: \(count)"
            }
        }
    }
    
    
    //send high score to leaderboard
    func saveHighscore(_ score:Int) {
        //check if user is signed in
        if GKLocalPlayer.localPlayer().isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: "leaderBoard") //leaderboard id here
            scoreReporter.value = Int64(score) //score variable here (same as above)
            let scoreArray: [GKScore] = [scoreReporter]
            GKScore.report(scoreArray, withCompletionHandler: {(error : Error?) -> Void in
                if error != nil {
                    print("error")
                }
            })
            //GKScore.reportScores(scoreArray, withCompletionHandler: )
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
