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
    var upperLayer: SKShapeNode?
    var logo = SKSpriteNode(imageNamed: "logo")
    var playButton = SKSpriteNode(imageNamed: "playButton")
    var leadersButton = SKSpriteNode(imageNamed: "leadersButton")
    var soundButton = SKSpriteNode(imageNamed: "soundOn")
    var nameMode = SKLabelNode(text: "Классический режим")
    
    var maze: Maze?
    var bgBasic: SKSpriteNode?
    var oldFingerPosition: CGPoint? = nil
    var resolution: Bool = false
    var restart  = SKSpriteNode(imageNamed: "restart")
    var lastUpdateTime: TimeInterval = 0.0
    var dt = 0.0
    var stopPlaying = true
    
    //Секундомер
    var count: Double = 0.0
    var timer = Timer()
    var timeLabel = SKLabelNode()
    //var bestTimeLabel = SKLabelNode()
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
    var featureIcon = SKSpriteNode()
    var featureText = SKLabelNode(fontNamed: "Myriad Pro")
    var soundButtonResultBg = SKSpriteNode(imageNamed: "soundOn")
    var leadersButtonResultBg = SKSpriteNode(imageNamed: "leadersButton")
    
    //Различная озвучка
    var coinSound: SKAction?
    var clickSound: SKAction?
    var hitSound: SKAction?
    var lvlUpSound: SKAction?
    
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
        defaults.set(0, forKey: "points")
        
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
        
        playButton.size = CGSize(width: 250, height: 110)
        playButton.position = CGPoint(x: 0, y: -150)
        upperLayer!.addChild(playButton)
        
        leadersButton.size = CGSize(width: 100, height: 100)
        leadersButton.position = CGPoint(x: 75, y: -295)
        upperLayer!.addChild(leadersButton)
        
        nameMode.fontColor = UIColor.black
        nameMode.fontSize = 34
        nameMode.fontName = "Tahoma"
        
        nameMode.position = CGPoint(x: 0, y: 170)
        upperLayer!.addChild(nameMode)
        
        if defaults.bool(forKey: "sound") { soundButton.texture = SKTexture(imageNamed: "soundOn") }
        else { soundButton.texture = SKTexture(imageNamed: "soundOff") }
        soundButton.size = CGSize(width: 100, height: 100)
        soundButton.position = CGPoint(x: -75, y: -295)
        upperLayer!.addChild(soundButton)
        
        
        if defaults.integer(forKey: "points") < 100 {
            defaults.set(100, forKey: "points")
        }
        
        
        //backgroundColor = SKColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
        backgroundColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        addBg() //Добавляем самый базовый background
        makeMaze() // Создаём и добавляем лабиринт
        addTimer() //Добавляем время
        addResult() //Добавляем результаты после прохождения
        //Restart
        restart.size = CGSize(width: 80, height: 80)
        restart.alpha = 0.8
        restart.position = CGPoint(x: size.width - 100, y: size.height - 80)
        addChild(restart)
        restart.isHidden = true
        //Кнопка в главное меню
        //Добавляем кол-во  монеток на экран
        addCoinsInfo()
        
        
        //Добавляем различную озвучку
        coinSound = SKAction.playSoundFileNamed("sounds/coin.mp3", waitForCompletion: false)
        clickSound = SKAction.playSoundFileNamed("sounds/click.mp3", waitForCompletion: false)
        hitSound = SKAction.playSoundFileNamed("sounds/click.mp3", waitForCompletion: false)
        lvlUpSound = SKAction.playSoundFileNamed("sounds/lvlUp.mp3", waitForCompletion: false)
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
            case 1:
                if self.defaults.bool(forKey: "sound") {
                    run(hitSound!)
                }
                weLosed()
                break
            case 2:
                defaults.set(defaults.integer(forKey: "coins") + 1, forKey: "coins")
                coinsCountLabel.text = "\(defaults.integer(forKey: "coins")) coins"
                //Музыка, когда подобрали монетку
                if self.defaults.bool(forKey: "sound") {
                    run(coinSound!)
                }
                break
            default: break
            }
            
        }
    }
    override func didFinishUpdate() {
        if !stopPlaying {
            if maze!.moveResolution == false {
                switch maze!.movePlayerDirection {
                case 0:
                    if maze!.player!.position.y >= maze!.willPlayerPosition.y {
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 1:
                    if maze!.player!.position.x >= maze!.willPlayerPosition.x {
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 2:
                    if maze!.player!.position.y <= maze!.willPlayerPosition.y {
                        maze!.player!.position.y = -CGFloat(maze!.playerPosition.i) * maze!.blockSize!.height - maze!.player!.frame.height / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
                        if maze!.willPlayerDirection != nil {
                            maze!.movePlayer(maze!.willPlayerDirection!, playerSpeadChange: true)
                            maze!.willPlayerDirection = nil
                        }
                    }
                case 3:
                    if maze!.player!.position.x <= maze!.willPlayerPosition.x {
                        maze!.player!.position.x = CGFloat(maze!.playerPosition.j) * maze!.blockSize!.width + maze!.player!.frame.width / 2
                        maze!.movePlayerDirection = 4
                        maze!.moveResolution = true
                        maze!.stopPlayerAnimation()
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
                    self.restart.isHidden = false
                    self.stopPlaying = false
                    if self.defaults.bool(forKey: "sound") {
                        self.run(self.clickSound!)
                    }
                })]))
            case restart:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                maze!.bg!.removeFromParent()
                timer.invalidate()
                makeMaze()
            case continueButton:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                maze!.bg!.removeFromParent()
                stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                resultBg!.isHidden = true
                makeMaze()
            case leadersButton, leadersButtonResultBg:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                showLeader()
            case soundButtonResultBg, soundButton:
                if defaults.bool(forKey: "sound") {
                    run(clickSound!)
                }
                if defaults.bool(forKey: "sound") {
                    soundButtonResultBg.texture = SKTexture(imageNamed: "soundOff")
                    soundButton.texture = SKTexture(imageNamed: "soundOff")
                    defaults.set(false, forKey: "sound")
                    SKTAudio.sharedInstance().pauseBackgroundMusic()
                } else {
                    soundButtonResultBg.texture = SKTexture(imageNamed: "soundOn")
                    soundButton.texture = SKTexture(imageNamed: "soundOn")
                    defaults.set(true, forKey: "sound")
                    SKTAudio.sharedInstance().resumeBackgroundMusic()
                }
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
        //print("You won")
        timer.invalidate()
        /*if count < defaults.double(forKey: "bestTime") || defaults.double(forKey: "bestTime") == 0.0 {
            defaults.set(count, forKey: "bestTime")
            results = defaults.double(forKey: "bestTime")
        }*/
        
        countLvlUp = (defaults.integer(forKey: "points") % 100 + Int(350/count)) / 100
        showResultBg(true)
        
        saveHighscore(defaults.integer(forKey: "points") / 100)
    }
    
    func weLosed() {
        //print("You losed!")
        timer.invalidate()
        countLvlUp = 0
        showResultBg(false)
    }
    
    func showResultBg(_ win: Bool) {
        if featureIcon.parent != nil {
            featureIcon.removeFromParent()
        }
        if featureText.parent != nil {
            featureText.removeFromParent()
        }
        
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
        if countLvlUp == 0 {
            lvlLineMask.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.moveBy(x: dtWithLvlLine!, y: 0, duration: 1)
            ]))
        } else if countLvlUp == 1 {
            lvlLineMask.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.moveBy(x: lvlLine!.size.width - CGFloat(defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * lvlLine!.size.width, y: 0, duration: 2),
                SKAction.run({
                    self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                    if self.defaults.bool(forKey: "sound") {
                        self.run(self.lvlUpSound!)
                    }
                    self.lvlFeatures(lvl: Int(self.defaults.integer(forKey: "points") / 100)) //Когда подняли уровень, появляется описание его открытий
                    self.currentLvl.text = "\(Int(self.defaults.integer(forKey: "points") / 100)) lvl"
                    self.nextLvl.text = "\(Int(self.defaults.integer(forKey: "points") / 100) + 1) lvl"
                    //print("lvlUp")
                }),
                SKAction.wait(forDuration: 1.5),
                SKAction.moveBy(x: dtWithLvlLine2, y: 0, duration: 2)
                ]))
        } else if countLvlUp > 1 {
            lvlLineMask.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.moveBy(x: lvlLine!.size.width - CGFloat(defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * lvlLine!.size.width, y: 0, duration: 2),
                SKAction.run({
                    self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                    self.lvlFeatures(lvl: Int(self.defaults.integer(forKey: "points") / 100)) //Когда подняли уровень, появляется описание его открытий
                    self.dtWithLvlLine! -= self.lvlLine!.size.width + CGFloat(self.defaults.integer(forKey: "points")).truncatingRemainder(dividingBy: 100) / 100 * self.lvlLine!.size.width
                }),
                SKAction.repeat(SKAction.sequence([
                    SKAction.moveBy(x: lvlLine!.size.width, y: 0, duration: 2),
                    SKAction.run({
                        self.lvlLineMask.position.x = -self.lvlLine!.size.width * 1.5
                        if self.defaults.bool(forKey: "sound") {
                            self.run(self.lvlUpSound!)
                        }
                        self.dtWithLvlLine! -= self.lvlLine!.size.width
                    })
                    ]), count: countLvlUp - 2),
                SKAction.wait(forDuration: 1.5),
                SKAction.moveBy(x: self.dtWithLvlLine!, y: 0, duration: 2)
                ]))
        }
        
        defaults.set(defaults.integer(forKey: "points") + (Int(350/count)), forKey: "points")
    }
    
    func lvlFeatures(lvl: Int) {
        switch lvl {
        case 2:
            featureIcon.texture = SKTexture(imageNamed: "resize")
            featureText.text = "Теперь размер лабиринта 11x11"
        case 3:
            featureIcon.texture = SKTexture(imageNamed: "stopTimer")
            featureText.text = "Останавливает время на 4 секунды"
        case 4:
            featureIcon.texture = SKTexture(imageNamed: "resize")
            featureText.text = "Теперь размер лабиринта 13x13"
        case 5:
            featureIcon.texture = SKTexture(imageNamed: "speedRoadBig")
            featureText.text = "Могут тебя как ускорять, так и замедлять"
        case 7:
            featureIcon.texture = SKTexture(imageNamed: "resize")
            featureText.text = "Теперь размер лабиринта 15x15"
        case 10:
            featureIcon.texture = SKTexture(imageNamed: "resize")
            featureText.text = "Теперь размер лабиринта 17x17"
        case 14:
            featureIcon.texture = SKTexture(imageNamed: "resize")
            featureText.text = "Теперь размер лабиринта 19x19"
        case 18:
            featureIcon.texture = SKTexture(imageNamed: "tp1")
            featureText.text = "Переносит тебя к такому же телепорту"
        case 22:
            featureIcon.texture = SKTexture(imageNamed: "tp2")
            featureText.text = "Ещё одна пара телепортов"
        case 26:
            featureIcon.texture = SKTexture(imageNamed: "robot")
            featureText.text = "Его лучше не касаться"
        case 100:
            featureText.text = "Ты крутой!"
        default:
            break
        }
        
        featureIcon.position = CGPoint(x: 0, y: 330)
        featureIcon.size = CGSize(width: 150, height: 150)
        resultBg!.addChild(featureIcon)
        
        featureText.position = CGPoint(x: 0, y: 200)
        featureText.fontColor = SKColor.yellow
        featureText.fontSize = 32
        resultBg!.addChild(featureText)
    }
    
    func makeMaze() {
        switch Int(defaults.integer(forKey: "points") / 100) {
        case 1: maze = Maze(blockCount: 9, mazeSize: CGSize(width: size.width * 0.6, height: size.height * 0.6), finishBlockI: 7, finishBlockJ: 7)
        case 2:  maze = Maze(blockCount: 11, mazeSize: CGSize(width: size.width * 0.67, height: size.height * 0.67), finishBlockI: 9, finishBlockJ: 9)
        case 3: maze = Maze(blockCount: 11, mazeSize: CGSize(width: size.width * 0.67, height: size.height * 0.67), finishBlockI: 9, finishBlockJ: 9, timer: 1)
        case 4: maze = Maze(blockCount: 13, mazeSize: CGSize(width: size.width * 0.72, height: size.height * 0.72), finishBlockI: 11, finishBlockJ: 11, timer: 1)
        case 5...6: maze = Maze(blockCount: 13, mazeSize: CGSize(width: size.width * 0.72, height: size.height * 0.72), finishBlockI: 11, finishBlockJ: 11, timer: 1, speedRoads: true)
        case 7...9: maze = Maze(blockCount: 15, mazeSize: CGSize(width: size.width * 0.8, height: size.height * 0.8), finishBlockI: 13, finishBlockJ: 13, timer: 1, speedRoads: true)
        case 10...13: maze = Maze(blockCount: 17, mazeSize: CGSize(width: size.width * 0.9, height: size.height * 0.9), finishBlockI: 15, finishBlockJ: 15, timer: 1, speedRoads: true)
        case 14...17: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true)
        case 18...21: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 1)
        case 22...25: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2)
        
        case 26...999: maze = Maze(blockCount: 19, startBlockI: 1, startBlockJ: 1, mazeSize: CGSize(width: size.width, height: size.height), finishBlockI: 17, finishBlockJ: 17, timer: 1, speedRoads: true, teleports: 2, inversions: 1, warders: 1)
       
        default: break
        }
        
        bgBasic!.addChild(maze!.bg!)
        maze!.printMaze()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Competitive.counter), userInfo: nil, repeats: true)
        count = 0.0
    }
    
    func addResult() {
        if featureIcon.parent != nil {
            featureIcon.removeFromParent()
        }
        if featureText.parent != nil {
            featureText.removeFromParent()
        }
        
        
        resultBg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: self.size)
        resultBg!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resultBg!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        resultBg!.zPosition = 99
        addChild(resultBg!)
        resultBg!.isHidden = true
        
        continueButton.position = CGPoint(x: 0, y: -280)
        continueButton.size = CGSize(width: 397, height: 136)
        resultBg!.addChild(continueButton)
        
        if defaults.integer(forKey: "points") == 0 {
            defaults.set(100, forKey: "points")
        }
        
        plusPercent.position = CGPoint(x: 0, y: 60)
        plusPercent.fontColor = SKColor.white
        plusPercent.fontSize = 120.0
        resultBg!.addChild(plusPercent)
        
        currentLvl.position = CGPoint(x: -240, y: -110)
        currentLvl.fontColor = SKColor.white
        currentLvl.fontSize = 44.0
        resultBg!.addChild(currentLvl)
        
        nextLvl.position = CGPoint(x: 240, y: -110)
        nextLvl.fontColor = SKColor.white
        nextLvl.fontSize = 44.0
        resultBg!.addChild(nextLvl)
        
        bgLvlLine = SKSpriteNode(color: UIColor.white, size: CGSize(width: size.width * 0.8 + 20, height: 60))
        bgLvlLine!.position = CGPoint(x: 0, y: -10)
        resultBg!.addChild(bgLvlLine!)
        
        lvlLine = SKSpriteNode(color: UIColor.black, size: CGSize(width: size.width * 0.8, height: 40))
        
        lvlLineMask = SKSpriteNode(color: UIColor.black, size: CGSize(width: size.width * 0.8, height: 40))
        lvlLineMask.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        lvlLineMask.position = CGPoint(x: -lvlLine!.size.width / 2, y: 0)
        
        cropNode.addChild(lvlLine!)
        cropNode.maskNode = lvlLineMask
        cropNode.position = CGPoint(x: 0, y: 0)
        bgLvlLine!.addChild(cropNode)
        
        if defaults.bool(forKey: "sound") { soundButtonResultBg.texture = SKTexture(imageNamed: "soundOn") }
        else { soundButtonResultBg.texture = SKTexture(imageNamed: "soundOff") }
        soundButtonResultBg.size = CGSize(width: 100, height: 100)
        soundButtonResultBg.position = CGPoint(x: self.size.width / 2 - soundButtonResultBg.size.width / 2 - 30, y: -self.size.height / 2 + soundButtonResultBg.size.height / 2 + 40)
        resultBg!.addChild(soundButtonResultBg)
        
        leadersButtonResultBg.size = CGSize(width: 100, height: 100)
        leadersButtonResultBg.position = CGPoint(x: self.size.width / 2 - soundButtonResultBg.size.width / 2 - 30 - 115, y: -self.size.height / 2 + soundButtonResultBg.size.height / 2 + 40)
        resultBg!.addChild(leadersButtonResultBg)
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
        coinIcon.zPosition = 99
        addChild(coinIcon)
        
        coinsCountLabel.text = "\(defaults.integer(forKey: "coins")) coins"
        coinsCountLabel.position = CGPoint(x: 100, y: 57)
        coinsCountLabel.horizontalAlignmentMode = .left
        coinsCountLabel.fontColor = SKColor.white
        coinsCountLabel.fontSize = 34
        coinsCountLabel.fontName = "Chalkboard SE Bold"
        coinsCountLabel.name = "coinsCount"
        coinsCountLabel.zPosition = 99
        addChild(coinsCountLabel)
    }
    
    func addTimer() {
        timeLabel.text = "Time: \(count)"
        timeLabel.position = CGPoint(x: 120, y: size.height - 90)
        timeLabel.fontColor = SKColor.white
        timeLabel.fontSize = 28
        timeLabel.fontName = "Chalkboard SE Bold"
        timeLabel.name = "timer"
        timeLabel.zPosition = 99
        addChild(timeLabel)
        
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
