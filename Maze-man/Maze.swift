//
//  Maze.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit
import GameKit

class Maze {
    var maze: [[UInt8]]? //Массив с блоками
    var blockCount: Int? //Кол-во блоков в строке и столбце
    var actualPoint: (i: Int, j: Int)? //Точка, в которой мы находимся сейчас (для генерации лабиринта)
    var whiteBlocks: [(i: Int, j: Int)] = [] //Все нечётные белые блоки (дорожки)
    var blockSize: CGSize? //Размер одного блока (зависит от размера экрана)
    var deadLocks: [(i: Int, j: Int)] = [] //Координаты всех тупиков
    //var arrayWithTP: [(teleport: SKShapeNode, i: Int, j: Int)] = [] //Массив с телепортами
    var arrayWithTP: [(teleport: SKSpriteNode, i: Int, j: Int)] = [] //Массив с телепортами
    var arrayWithInversions: [(inversion: SKSpriteNode, i: Int, j: Int)] = [] //Массив с блоками инверсии
    var stopTimers: [(SKSpriteNode, i: Int, j: Int)] = [] //Массив со всеми таймерами на лабиринте
    var startBlockPosition: (i: Int, j: Int)
    var finishBlockPosition: (i: Int, j: Int)
    //Для вывода на экран лабиринта
    var bg: SKSpriteNode?
    var mazeSize: CGSize
    var mazePath = UIBezierPath() //CGPathCreateMutable()
    var mazeShape: SKShapeNode?
    //var startBlock: SKShapeNode? //Блок стартаx
    var finishBlock: SKSpriteNode? //Блок финиша
    //Для ускорялок
    var square: [[Bool]] //Делим лабиринт на квадраты (9на9) и если там есть ускорялка ставим true
    var speedRoads: [(i: Int, j: Int, direction: Int,backBorder: Bool)] = [] //Записываем координаты, направление ускорителя и возможность продления ускорялки назад
    //Всё, что связано с плеером
    var player: SKSpriteNode?
    let playerAnimation: SKAction //Для анимации плеера
    var playerPosition: (i: Int, j: Int)
    //Всё для движения плеера
    var willPlayerPosition: CGPoint!
    var willPlayerDirection: Int?
    var playerSpeed: CGFloat?
    var kSpeed: CGFloat = 1.0
    var movePlayerDirection = 4 //Куда плееру двигаться; если 4, то он стоит на месте
    var moveResolution = true
    var speedTimer: Double = 0.0 //Время для ускорялок
    var playTimer = true //Если false, то таймер на паузе
    var warderVariants: [(i: Int, j: Int, direction: Int)] = [] //Задаём позицию и направление смотрителя (всех возможных)
    var coins: [(coin: SKSpriteNode, i: Int, j: Int)] = [] //Используем только при построении, при игре - нет
    var competitiveMod: Bool //Если режим лабиринта соревновательный, то true, если свободный - false
    let defaults = UserDefaults.standard
    
    //Всё для мультиплеера
    //Для мультиплеера соперник
    var rivalPlayer: SKSpriteNode?
    //Всё для движения плеера соперника
    var rivalPosition: (i: Int, j: Int)?
    var willRivalPosition: CGPoint?
    var willRivalDirection: Int?
    var rivalSpeed: CGFloat?
    var moveRivalDirection = 4 //Куда плееру двигаться; если 4, то он стоит на месте
    var moveRivalResolution = true
    var rivalSpeedK: CGFloat? //Коэффикиент скорости нашего соперника (меняется прокачкой)
    //Наш матч
    var match: GKMatch?
    
    var allSceneries: [String] = ["scenery-dust","scenery-green","scenery-snow"] // добавляем различные скины для сцен
    var randomScenery: String
    
    //Различная озвучка
    var tpSound: SKAction?
    var timerSound: SKAction?
    var speedUpSound: SKAction?
    var speedDownSound: SKAction?
    
    
    init(competitiveMod: Bool = true, blockCount: Int, startBlockI: Int = 1, startBlockJ: Int = 1, mazeSize: CGSize? = nil, finishBlockI: Int, finishBlockJ: Int, timer: Int = 0, speedRoads: Bool = false, teleports: Int = 0, inversions: Int = 0, warders: Int = 0, match: GKMatch? = nil) {
        self.blockCount = blockCount
        self.startBlockPosition = (i: startBlockI, j: startBlockJ)
        self.finishBlockPosition = (i: finishBlockI, j: finishBlockJ)
        self.actualPoint = self.startBlockPosition
        self.competitiveMod = competitiveMod
        randomScenery = allSceneries[Int(random(min: 0, max: CGFloat(allSceneries.count)))]
        if mazeSize == nil {
            self.mazeSize = CGSize(width: blockCount * 30, height: blockCount * 30)
        } else {
            self.mazeSize = mazeSize!
        }
        playerPosition = (i: self.startBlockPosition.i, j: self.startBlockPosition.j)
        whiteBlocks.append((i: startBlockI, j: startBlockI))
        square = [[Bool]](repeating: [Bool](repeating: false, count: blockCount/9 + 1), count: blockCount/9 + 1)
        maze = [[UInt8]](repeating: [UInt8](repeating: 0, count: blockCount), count: blockCount)
        
        var playerTextures: [SKTexture] = []
        for i in 1...2 {
            playerTextures.append(SKTexture(imageNamed: "player\(i)"))
        }
        playerAnimation = SKAction.repeatForever(SKAction.animate(with: playerTextures, timePerFrame: 0.3))
        
        if competitiveMod {
            print("CompetitiveMod")
            
            generateMaze()
            addBg()
            generateShape2()
            startAndFinishBlocks()
            playerSettings()
            self.willPlayerPosition = player!.position
            
            if timer > 0 {
                generateTimer(timer)
                timerSound = SKAction.playSoundFileNamed("sounds/timer.mp3", waitForCompletion: false)
            }
            if speedRoads {
                addSpeedRoads()
                speedUpSound = SKAction.playSoundFileNamed("sounds/speedUp.m4a", waitForCompletion: false)
                speedDownSound = SKAction.playSoundFileNamed("sounds/speedDown.mp3", waitForCompletion: false)
            }
            if teleports > 0 {
                addTeleport(teleports * 2)
                tpSound = SKAction.playSoundFileNamed("sounds/tp.mp3", waitForCompletion: false)
            }
            //if inversions > 0 { addInversion(inversions) } //Потом добавить
            if warders > 0 { addWarders(warders) }
            addCoins()
        } else {
            print("FreeMod")
            
            addBg()
            
            playerSettings()
            rivalSettings() //Отображаем вржеского плеера
            self.willPlayerPosition = player!.position
            self.willRivalPosition = rivalPlayer!.position
            if match != nil {
                self.match = match
            }
            

        }
    }
    
    func startForMultiGame() {
        //Отправляем свой скин и скорость сопернику
        do {
            try self.match!.sendData(toAllPlayers: NSData(bytes: [0, UInt8(defaults.integer(forKey: "speed"))] as [UInt8], length: 2) as Data, with: GKMatchSendDataMode.reliable)
        } catch {
            print("Some error in sendData")
        }
        //Считается что массив с лабиринтом уже есть
        //Дальше идёт прорисовка
        printMaze()
        generateShape2()
        startAndFinishBlocks()
    }
    
    func playerSettings() {
        player = SKSpriteNode(imageNamed: "player0")
        player!.name = "player"
        player!.size = blockSize!
        player!.position = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
        player!.zPosition = 5
        bg!.addChild(player!)
    }
    
    //Отвечает за отображение персонажа соперника в мультиплеере
    func rivalSettings() {
        rivalPlayer = SKSpriteNode(imageNamed: "player0")
        rivalPlayer!.name = "rival"
        rivalPlayer!.size = blockSize!
        rivalPlayer!.position = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
        rivalPlayer!.zPosition = 5
        rivalPlayer!.alpha = 0.5
        rivalPosition = (i: self.startBlockPosition.i, j: self.startBlockPosition.j)
        bg!.addChild(rivalPlayer!)
    }
    
    //Передвигаем плеера по лабиринту
    func movePlayer(_ direction: Int, playerSpeadChange: Bool) {
        //Если у нас мультиплеер, то передаём сопернику наше напралвние (только когда мы сами начинаем двигаться, а не заранее)
        if match != nil {
            do {
                try match!.sendData(toAllPlayers: NSData(bytes: [UInt8(direction)] as [UInt8], length: 1) as Data, with: GKMatchSendDataMode.reliable)
            } catch {
                print("Some error in sendData")
            }
        }
        var count = 0
        var qweq: Int = 0 //Чтобы не ругался на too complex в условии while
        var qwew: Int = 0 //Чтобы не ругался на too complex в условии while
        var qwee: Int = 0 //Чтобы не ругался на too complex в условии while
        switch direction {
        case 0:
            player!.zRotation = Pi/2
            if maze![playerPosition.i - 1][playerPosition.j] != 0 {
                print("q0")
                qweq = 0
                qwew = 0
                qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![Int(playerPosition.i - count)][Int(playerPosition.j + 1)])
                    qwew = Int(maze![playerPosition.i - count][playerPosition.j - 1])
                    qwee = Int(maze![playerPosition.i - count - 1][playerPosition.j])
                }
                while(qweq == 0 && qwew == 0 && qwee != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height + CGFloat(count) * player!.frame.height)
                startPlayerAnimation()
            }
        case 1:
            player!.zRotation = 0
            if maze![playerPosition.i][playerPosition.j + 1] != 0 {
                print("q1")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![playerPosition.i + 1][playerPosition.j + count])
                    qwew = Int(maze![playerPosition.i - 1][playerPosition.j + count])
                    qwee = Int(maze![playerPosition.i][playerPosition.j + count + 1])
                }
                while(qweq == 0 && qwew == 0 && qwee != 0)
                willPlayerPosition.x = player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width  + CGFloat(count) * player!.frame.width
                willPlayerPosition.y = -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height
                startPlayerAnimation()
            }
        case 2:
            player!.zRotation = -Pi/2
            if maze![playerPosition.i + 1][playerPosition.j] != 0 {
                print("q2")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![playerPosition.i + count][playerPosition.j + 1])
                    qwew = Int(maze![playerPosition.i + count][playerPosition.j - 1])
                    qwee = Int(maze![playerPosition.i + count + 1][playerPosition.j])
                } while(qweq == 0 && qwew == 0 && qwee != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height - CGFloat(count) * player!.frame.height)
                startPlayerAnimation()
            }
        case 3:
            player!.zRotation = Pi
            if maze![playerPosition.i][playerPosition.j - 1] != 0 {
                print("q3")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![playerPosition.i + 1][playerPosition.j - count])
                    qwew = Int(maze![playerPosition.i - 1][playerPosition.j - count])
                    qwee = Int(maze![playerPosition.i][playerPosition.j - count - 1])
                }
                while(qweq == 0 && qwew == 0 && qwee != 0)
                
                willPlayerPosition.x = player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width - CGFloat(count) * player!.frame.width
                willPlayerPosition.y = -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height
                startPlayerAnimation()
            }
        default: break
        }
        moveResolution = false
        movePlayerDirection = direction
        if playerSpeadChange {
            playerSpeed = sqrt(CGFloat(count)) * blockSize!.width * 1.5 + 3 + CGFloat(defaults.integer(forKey: "speed")) //Скорость пикселей в секунду
        }
    }
    
    
    //Передвигаем плеера соперника по лабиринту
    func moveRival(_ direction: Int, playerSpeadChange: Bool) {
        var count = 0
        var qweq: Int = 0 //Чтобы не ругался на too complex в условии while
        var qwew: Int = 0 //Чтобы не ругался на too complex в условии while
        var qwee: Int = 0 //Чтобы не ругался на too complex в условии while
        switch direction {
        case 0:
            rivalPlayer!.zRotation = Pi/2
            if maze![rivalPosition!.i - 1][rivalPosition!.j] != 0 {
                qweq = 0
                qwew = 0
                qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![Int(rivalPosition!.i - count)][Int(rivalPosition!.j + 1)])
                    qwew = Int(maze![rivalPosition!.i - count][rivalPosition!.j - 1])
                    qwee = Int(maze![rivalPosition!.i - count - 1][rivalPosition!.j])
                } while(qweq == 0 && qwew == 0 && qwee != 0)
                willRivalPosition = CGPoint(x: rivalPlayer!.frame.width / 2 + CGFloat(rivalPosition!.j) * player!.frame.width, y: -rivalPlayer!.frame.height / 2 - CGFloat(rivalPosition!.i) * rivalPlayer!.frame.height + CGFloat(count) * rivalPlayer!.frame.height)
            }
        case 1:
            rivalPlayer!.zRotation = 0
            if maze![rivalPosition!.i][rivalPosition!.j + 1] != 0 {
                print("q1")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![rivalPosition!.i + 1][rivalPosition!.j + count])
                    qwew = Int(maze![rivalPosition!.i - 1][rivalPosition!.j + count])
                    qwee = Int(maze![rivalPosition!.i][rivalPosition!.j + count + 1])
                }
                    while(qweq == 0 && qwew == 0 && qwee != 0)
                //
                willRivalPosition?.x = rivalPlayer!.frame.width / 2 + CGFloat(rivalPosition!.j) * rivalPlayer!.frame.width  + CGFloat(count) * rivalPlayer!.frame.width
                willRivalPosition?.y = -rivalPlayer!.frame.height / 2 - CGFloat(rivalPosition!.i) * rivalPlayer!.frame.height
            }
        case 2:
            rivalPlayer!.zRotation = -Pi/2
            if maze![rivalPosition!.i + 1][rivalPosition!.j] != 0 {
                print("q2")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![rivalPosition!.i + count][rivalPosition!.j + 1])
                    qwew = Int(maze![rivalPosition!.i + count][rivalPosition!.j - 1])
                    qwee = Int(maze![rivalPosition!.i + count + 1][rivalPosition!.j])
                } while(qweq == 0 && qwew == 0 && qwee != 0)
                willRivalPosition = CGPoint(x: rivalPlayer!.frame.width / 2 + CGFloat(rivalPosition!.j) * rivalPlayer!.frame.width, y: -rivalPlayer!.frame.height / 2 - CGFloat(rivalPosition!.i) * rivalPlayer!.frame.height - CGFloat(count) * rivalPlayer!.frame.height)
            }
        case 3:
            rivalPlayer!.zRotation = Pi
            if maze![rivalPosition!.i][rivalPosition!.j - 1] != 0 {
                print("q3")
                qweq = 0; qwew = 0; qwee = 0
                repeat {
                    count += 1
                    qweq = Int(maze![rivalPosition!.i + 1][rivalPosition!.j - count])
                    qwew = Int(maze![rivalPosition!.i - 1][rivalPosition!.j - count])
                    qwee = Int(maze![rivalPosition!.i][rivalPosition!.j - count - 1])
                }
                    while(qweq == 0 && qwew == 0 && qwee != 0)
                
                willRivalPosition?.x = rivalPlayer!.frame.width / 2 + CGFloat(rivalPosition!.j) * rivalPlayer!.frame.width - CGFloat(count) * rivalPlayer!.frame.width
                willRivalPosition?.y = -rivalPlayer!.frame.height / 2 - CGFloat(rivalPosition!.i) * rivalPlayer!.frame.height
            }
        default: break
        }
        moveRivalResolution = false
        moveRivalDirection = direction
        if playerSpeadChange {
            rivalSpeed = sqrt(CGFloat(count)) * blockSize!.width * 1.5 + 3 + rivalSpeedK! //Скорость пикселей в секунду
        }
    }
    
    
    //Генерируем лабиринт
    func generateMaze() {
        while checkBlocks() {
            checkWhiteBlocks()
            let randWhiteBlockNumber = Int(random(min: 0, max: CGFloat(whiteBlocks.count)))
            actualPoint = whiteBlocks[randWhiteBlockNumber]
            generateWay() //Генерируем проход лабиринта
        }
    }
    
    //Гененируем одну дорожку
    func generateWay() {
        maze![actualPoint!.i][actualPoint!.j] = 1
        var sides = checkSides(actualPoint!.i, positionJ: actualPoint!.j)
        while(sides.top || sides.right || sides.bottom || sides.left) {
            var direction: Int?
            switch (sides.top, sides.right,sides.bottom,sides.left) {
            case (false,false,false,true): direction = 3; break
            case (false,false,true,false): direction = 2; break
            case (false,false,true,true): direction = Int(random(min: 2, max: 4)); break
            case (false,true,false,false): direction = 1; break
            case (false,true,false,true): direction = Int(random(min: 1, max: 3)) * 2 - 1; break
            case (false,true,true,false): direction = Int(random(min: 1, max: 3)); break
            case (false,true,true,true): direction = Int(random(min: 1, max: 4)); break
            case (true,false,false,false): direction = 0; break
            case (true,false,false,true): direction = Int(random(min: 0, max: 2)) * 3; break
            case (true,false,true,false): direction = Int(random(min: 0, max: 2)) * 2; break
            case (true,false,true,true): direction = Int(random(min: 1, max: 4)); if direction == 1 {direction = 0}; break
            case (true,true,false,false): direction = Int(random(min: 0, max: 2)); break
            case (true,true,false,true): direction = Int(random(min: 0, max: 3)); if direction == 2 {direction = 3}; break
            case (true,true,true,false): direction = Int(random(min: 0, max: 3)); break
            case (true,true,true,true): direction = Int(random(min: 0, max: 4)); break
            default: break
            }
            switch direction! {
            case 0:
                maze![actualPoint!.i - 1][actualPoint!.j] = 1
                maze![actualPoint!.i - 2][actualPoint!.j] = 1
                actualPoint!.i -= 2
                if maze![actualPoint!.i + 3][actualPoint!.j] == 1 && maze![actualPoint!.i + 2][actualPoint!.j + 1] == 0 && maze![actualPoint!.i + 2][actualPoint!.j - 1] == 0 && square[Int((actualPoint!.i + 3) / 9)][Int(actualPoint!.j / 9)] == false && random(min: 0, max: 1) < 0.25 {
                    speedRoads.append((i: actualPoint!.i + 3, j: actualPoint!.j, direction: direction!,backBorder: false))
                    if maze![actualPoint!.i + 5][actualPoint!.j] == 1 && maze![actualPoint!.i + 4][actualPoint!.j + 1] == 0 && maze![actualPoint!.i + 4][actualPoint!.j - 1] == 0 {
                        speedRoads[speedRoads.count - 1].backBorder = true
                    }
                    square[Int((actualPoint!.i + 3) / 9)][Int(actualPoint!.j / 9)] = true
                }
                else if maze![actualPoint!.i + 3][actualPoint!.j] == 1 {
                    if maze![actualPoint!.i + 2][actualPoint!.j + 1] == 1 {
                        warderVariants.append((i: actualPoint!.i + 4, j: actualPoint!.j, direction: 0))
                    }
                    if maze![actualPoint!.i + 2][actualPoint!.j - 1] == 1 {
                        warderVariants.append((i: actualPoint!.i + 4, j: actualPoint!.j, direction: 0))
                    }
                }
            case 1:
                maze![actualPoint!.i][actualPoint!.j + 1] = 1
                maze![actualPoint!.i][actualPoint!.j + 2] = 1
                actualPoint!.j += 2
                if maze![actualPoint!.i][actualPoint!.j - 3] == 1 && maze![actualPoint!.i - 1][actualPoint!.j - 2] == 0 && maze![actualPoint!.i + 1][actualPoint!.j - 2] == 0 && square[Int(actualPoint!.i / 9)][Int((actualPoint!.j - 3) / 9)] == false && random(min: 0, max: 1) < 0.25 {
                    speedRoads.append((i: actualPoint!.i, j: actualPoint!.j - 3, direction: direction!,backBorder: false))
                    if maze![actualPoint!.i][actualPoint!.j - 5] == 1 && maze![actualPoint!.i - 1][actualPoint!.j - 4] == 0 && maze![actualPoint!.i + 1][actualPoint!.j - 4] == 0{
                        speedRoads[speedRoads.count - 1].backBorder = true
                    }
                    square[Int(actualPoint!.i / 9)][Int((actualPoint!.j - 3) / 9)] = true
                }
                else if maze![actualPoint!.i][actualPoint!.j - 3] == 1 {
                    if maze![actualPoint!.i - 1][actualPoint!.j - 2] == 1 {
                        warderVariants.append((i: actualPoint!.i, j: actualPoint!.j - 4, direction: 1))
                    }
                    if maze![actualPoint!.i + 1][actualPoint!.j - 2] == 1 {
                        warderVariants.append((i: actualPoint!.i, j: actualPoint!.j - 4, direction: 1))
                    }
                }
            case 2:
                maze![actualPoint!.i + 1][actualPoint!.j] = 1
                maze![actualPoint!.i + 2][actualPoint!.j] = 1
                actualPoint!.i += 2
                if maze![actualPoint!.i - 3][actualPoint!.j] == 1 && maze![actualPoint!.i - 2][actualPoint!.j + 1] == 0 && maze![actualPoint!.i - 2][actualPoint!.j - 1] == 0 && square[Int((actualPoint!.i - 3) / 9)][Int(actualPoint!.j / 9)] == false && random(min: 0, max: 1) < 0.25 {
                    speedRoads.append((i: actualPoint!.i - 3, j: actualPoint!.j, direction: direction!, backBorder: false))
                    if maze![actualPoint!.i - 5][actualPoint!.j] == 1 && maze![actualPoint!.i - 4][actualPoint!.j + 1] == 0 && maze![actualPoint!.i - 4][actualPoint!.j - 1] == 0{
                        speedRoads[speedRoads.count - 1].backBorder = true
                    }
                    square[Int((actualPoint!.i - 3) / 9)][Int(actualPoint!.j / 9)] = true
                }
                else if maze![actualPoint!.i - 3][actualPoint!.j] == 1 {
                    if maze![actualPoint!.i - 2][actualPoint!.j + 1] == 1 {
                        warderVariants.append((i: actualPoint!.i - 4, j: actualPoint!.j, direction: 2))
                    }
                    if maze![actualPoint!.i - 2][actualPoint!.j - 1] == 1 {
                        warderVariants.append((i: actualPoint!.i - 4, j: actualPoint!.j, direction: 2))
                    }
                }
            case 3:
                maze![actualPoint!.i][actualPoint!.j - 1] = 1
                maze![actualPoint!.i][actualPoint!.j - 2] = 1
                actualPoint!.j -= 2
                if maze![actualPoint!.i][actualPoint!.j + 3] == 1 && maze![actualPoint!.i - 1][actualPoint!.j + 2] == 0 && maze![actualPoint!.i + 1][actualPoint!.j + 2] == 0 && square[Int(actualPoint!.i / 9)][Int((actualPoint!.j + 3) / 9)] == false && random(min: 0, max: 1) < 0.25 {
                    speedRoads.append((i: actualPoint!.i, j: actualPoint!.j + 3, direction: direction!,backBorder: false))
                    if maze![actualPoint!.i][actualPoint!.j + 5] == 1 && maze![actualPoint!.i - 1][actualPoint!.j + 4] == 0 && maze![actualPoint!.i + 1][actualPoint!.j + 4] == 0{
                        speedRoads[speedRoads.count - 1].backBorder = true
                    }
                    square[Int(actualPoint!.i / 9)][Int((actualPoint!.j + 3) / 9)] = true
                }
                else if maze![actualPoint!.i][actualPoint!.j + 3] == 1 {
                    if maze![actualPoint!.i - 1][actualPoint!.j + 2] == 1 {
                        warderVariants.append((i: actualPoint!.i, j: actualPoint!.j + 4, direction: 3))
                    }
                    if maze![actualPoint!.i + 1][actualPoint!.j + 2] == 1 {
                        warderVariants.append((i: actualPoint!.i, j: actualPoint!.j + 4, direction: 3))
                    }
                }
            default: break
            }
            whiteBlocks.append((i: actualPoint!.i, j: actualPoint!.j))
            sides = checkSides(actualPoint!.i, positionJ: actualPoint!.j)
        }
    }
    
    //Проверяем, заполнен массив или нет
    func checkBlocks() -> Bool {
        var q = false
        for i in stride(from: 1, to: maze!.count, by: 2) {
            for j in stride(from: 1, to: maze![0].count, by: 2) {
                if maze![i][j] == 0 {
                    q = true
                    break
                }
            }
        }
        return q
    }
    //Удаляем белые блоки, которые окружены другими белыми блоками(чтобы не продолжать лабиринт оттуда)
    func checkWhiteBlocks() {
        for (index, i) in whiteBlocks.enumerated() {
            let q = checkSides(i.i, positionJ: i.j)
            if (q.top == false && q.right == false && q.bottom == false && q.left == false) {
                whiteBlocks.remove(at: index)
                checkWhiteBlocks()
                break
            }
        }
    }
    //На чём стоит лабиринт
    func addBg() {
        bg = SKSpriteNode(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), size: CGSize(width: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!, height: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!))
        bg!.size = CGSize(width: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!, height: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!)
        if competitiveMod { bg!.position = CGPoint(x: -bg!.frame.width / 2, y: bg!.frame.height / 2) } //Если соревновательный режим, то лабиринт по середине
        else { bg!.position = CGPoint(x: 0, y: 0) } //Если свободный, то начиная с левого верхнево угла
        bg!.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        blockSize = CGSize(width: bg!.frame.width / CGFloat(blockCount!) , height: bg!.frame.width / CGFloat(blockCount!))
        blockSize!.height = CGFloat(Int(blockSize!.height))
        blockSize!.width = CGFloat(Int(blockSize!.width))
        if Int(blockSize!.height) % 2 == 1 {
            blockSize!.height -= 1
        }
        if Int(blockSize!.width) % 2 == 1 {
            blockSize!.width -= 1
        }
        let atlas: SKTextureAtlas? = SKTextureAtlas(named: randomScenery)
        for row in 1..<maze!.count-1 {
            let tile = SKSpriteNode(texture:atlas!.textureNamed("bgtile-left"))
            tile.size = blockSize!
            tile.position = CGPoint(x: CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(row) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
            tile.zPosition = 1
            bg!.addChild(tile)
            
            let tileright = SKSpriteNode(texture:atlas!.textureNamed("bgtile-right"))
            tileright.size = blockSize!
            tileright.position = CGPoint(x: CGFloat(maze![0].count-1) * blockSize!.width + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(row) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
            bg!.addChild(tileright)
        }
        for col in 1..<maze![0].count-1 {
            let tile = SKSpriteNode(texture:atlas!.textureNamed("bgtile-top-mid"))
            tile.size = blockSize!
            tile.position = CGPoint(x: CGFloat(col) * blockSize!.width + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(Int(blockSize!.height / 2)))
            bg!.addChild(tile)
            
            let tilebot = SKSpriteNode(texture:atlas!.textureNamed("bgtile-bot-mid"))
            tilebot.size = blockSize!
            tilebot.position = CGPoint(x: CGFloat(col) * blockSize!.width + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(maze!.count-1) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
            bg!.addChild(tilebot)
        }
        
        let tiletopleft = SKSpriteNode(texture:atlas!.textureNamed("bgtile-top-left"))
        tiletopleft.size = blockSize!
        tiletopleft.position = CGPoint(x: CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(Int(blockSize!.height / 2)))
        bg!.addChild(tiletopleft)
        
        let tiletopright = SKSpriteNode(texture:atlas!.textureNamed("bgtile-top-right"))
        tiletopright.size = blockSize!
        tiletopright.position = CGPoint(x: CGFloat(maze![0].count-1) * blockSize!.width + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(Int(blockSize!.height / 2)))
        bg!.addChild(tiletopright)
        
        let tilebotleft = SKSpriteNode(texture:atlas!.textureNamed("bgtile-bot-left"))
        tilebotleft.size = blockSize!
        tilebotleft.position = CGPoint(x: CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(maze!.count-1) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
        bg!.addChild(tilebotleft)
        
        let tilebotright = SKSpriteNode(texture:atlas!.textureNamed("bgtile-bot-right"))
        tilebotright.size = blockSize!
        tilebotright.position = CGPoint(x: CGFloat(maze![0].count-1) * blockSize!.width + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(maze!.count-1) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
        bg!.addChild(tilebotright)
        
        //Заполняем всё зелёными квадратами (кроме граней)
        for i in 1..<maze!.count-1 {
            for j in 1..<maze![0].count-1 {
                let tile = SKSpriteNode(texture:atlas!.textureNamed("bgtile-main"))
                tile.size = blockSize!
                tile.position = CGPoint(x: CGFloat(j) * CGFloat(Int(blockSize!.width)) + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(i) * blockSize!.height - CGFloat(Int(blockSize!.height / 2)))
                bg!.addChild(tile)
            }
        }
    }
    
    //Даёт плееру анимацию
    func startPlayerAnimation() {
        if player!.action(forKey: "playerAnimation") == nil {
            player!.run(SKAction.repeatForever(playerAnimation), withKey: "playerAnimation")
        }
    }
    //Останавливает анимацию плееру
    func stopPlayerAnimation() {
        player!.removeAction(forKey: "playerAnimation")
        player!.texture = SKTexture(imageNamed: "player0")
    }
    
    //Выводим на экран старт и финиш
    func startAndFinishBlocks() {
        
        finishBlock = SKSpriteNode(imageNamed: "finishTile")
        finishBlock!.size = blockSize!
        finishBlock!.position = CGPoint(x: blockSize!.width * CGFloat(finishBlockPosition.j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(finishBlockPosition.i))
        finishBlock?.zPosition = 4
        bg!.addChild(finishBlock!)
        maze![finishBlockPosition.i][finishBlockPosition.j] = 19
    }
    
    //Проверяем выходит ли точка за рамки массива и свободно ли по сторонам
    func checkSides(_ positionI: Int, positionJ: Int) -> (top: Bool, right: Bool, bottom: Bool, left: Bool) {
        var sides = (top: true, right: true, bottom: true, left: true)
        switch positionI {
        case 0,1: sides.top = false
        case blockCount! - 2,blockCount! - 1: sides.bottom = false
        default: break
        }
        switch positionJ {
        case 0,1: sides.left = false
        case blockCount! - 2,blockCount! - 1: sides.right = false
        default: break
        }
        if sides.top {
            if maze![positionI - 2][positionJ] != 0 {
                sides.top = false
            }
        }
        if sides.right {
            if maze![positionI][positionJ + 2] != 0 {
                sides.right = false
            }
        }
        if sides.bottom {
            if maze![positionI + 2][positionJ] != 0 {
                sides.bottom = false
            }
        }
        if sides.left {
            if maze![positionI][positionJ - 2] != 0 {
                sides.left = false
            }
        }
        return sides
    }
    //Выводим матрицу лабиринта
    func printMaze() {
        for i in maze! {
            print(i)
        }
    }
    
    //Добавляем ускорялки
    func addSpeedRoads() {
        let count = speedRoads.count
        if count > 0 {
            for i in 0...count - 1 {
                maze![speedRoads[i].i][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                switch speedRoads[i].direction {
                case 0:
                    speedRoads.append((i: speedRoads[i].i - 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i - 1][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    speedRoads.append((i: speedRoads[i].i - 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i - 2][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i + 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i + 1][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                        speedRoads.append((i: speedRoads[i].i + 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i + 2][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    }
                case 1:
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 1, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j + 1] = UInt8(speedRoads[i].direction + 2)
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 2, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j + 2] = UInt8(speedRoads[i].direction + 2)
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 1, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j - 1] = UInt8(speedRoads[i].direction + 2)
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 2, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j - 2] = UInt8(speedRoads[i].direction + 2)
                    }
                case 2:
                    speedRoads.append((i: speedRoads[i].i + 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i + 1][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    speedRoads.append((i: speedRoads[i].i + 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i + 2][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i - 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i - 1][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                        speedRoads.append((i: speedRoads[i].i - 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i - 2][speedRoads[i].j] = UInt8(speedRoads[i].direction + 2)
                    }
                case 3:
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 1, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j - 1] = UInt8(speedRoads[i].direction + 2)
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 2, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j - 2] = UInt8(speedRoads[i].direction + 2)
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 1, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j + 1] = UInt8(speedRoads[i].direction + 2)
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 2, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j + 2] = UInt8(speedRoads[i].direction + 2)
                    }
                default: break
                }
            }
        }
        
        //Выводим ускорялки на экран
        for i in speedRoads {
            let speedRoad = SKSpriteNode(imageNamed: "speedRoad")
            speedRoad.zPosition = 3
            speedRoad.size = blockSize!
            speedRoad.position = CGPoint(x: blockSize!.width * CGFloat(i.j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(i.i))
            speedRoad.name = "speedRoad"
            switch i.direction {
            case 1: speedRoad.zRotation = Pi
            case 2: speedRoad.zRotation = Pi / 2
            case 3: speedRoad.zRotation = 0
            case 0: speedRoad.zRotation = -Pi / 2
            default: break
            }
            bg!.addChild(speedRoad)
        }
    }
    
    //Заполняем массив с тупиками
    func addDeadLocks(){
        if deadLocks.count == 0 {
            for i in stride(from: 1, to: maze!.count, by: 2) {
                for j in stride(from: 1, to: maze![0].count, by: 2) {
                    if checkDeadLock(i, positionJ: j) {
                        deadLocks.append((i: i, j: j))
                    }
                }
            }
            deadLocks.remove(at: 0)
            deadLocks.remove(at: deadLocks.count-1)
        }
    }
    //добалвяем таймер
    func generateTimer(_ count: Int) {
        for _ in 0...count - 1 {
            let stopTimer = SKSpriteNode(imageNamed: "stopTimer")
            stopTimer.name = "stopTimer"
            stopTimer.size = blockSize!
            stopTimer.zPosition = 4
            addDeadLocks() //Заполняем массив с тупиками
            if deadLocks.count > 0 {
                var randomDeadLock: Int?
                repeat {
                    randomDeadLock = Int(random(min: 0, max: CGFloat(deadLocks.count)))
                } while maze![deadLocks[randomDeadLock!].i][deadLocks[randomDeadLock!].j] != 1
                maze![deadLocks[randomDeadLock!].i][deadLocks[randomDeadLock!].j] = 6
                stopTimer.position = CGPoint(x: blockSize!.width * CGFloat(deadLocks[randomDeadLock!].j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(deadLocks[randomDeadLock!].i))
                stopTimers.append((stopTimer, i: deadLocks[randomDeadLock!].i, j: deadLocks[randomDeadLock!].j))
                bg!.addChild(stopTimers[stopTimers.count - 1].0)
                deadLocks.remove(at: randomDeadLock!)
            }
        }
    }
    // Добавляем телепорт
    func addTeleport(_ numberTeleports: Int) {
        addDeadLocks() //Заполняем массив с тупиками
        if deadLocks.count >= numberTeleports { //Если тупиков меньше, чем должно быть телепортов, то вообще не добавляем тп
            for i in 0...numberTeleports-1 {
                var randomDeadLockForTP: Int
                repeat {
                    randomDeadLockForTP = Int(random(min: 0, max: CGFloat(deadLocks.count)))
                } while maze![deadLocks[randomDeadLockForTP].i][deadLocks[randomDeadLockForTP].j] != 1
                maze![deadLocks[randomDeadLockForTP].i][deadLocks[randomDeadLockForTP].j] = UInt8(20 + i)
                arrayWithTP.append((teleport: SKSpriteNode(imageNamed: "tp1"), i: deadLocks[randomDeadLockForTP].i, j: deadLocks[randomDeadLockForTP].j))
                arrayWithTP[i].teleport.texture = imageTP(i)
                arrayWithTP[i].teleport.size = blockSize!
                arrayWithTP[i].teleport.run(SKAction.repeatForever(SKAction.rotate(byAngle: 2*Pi, duration: 0.8)))
                arrayWithTP[i].teleport.position = CGPoint(x: blockSize!.width * CGFloat(deadLocks[randomDeadLockForTP].j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(deadLocks[randomDeadLockForTP].i))
                arrayWithTP[i].teleport.zPosition = 3
                deadLocks.remove(at: randomDeadLockForTP)
                bg!.addChild(arrayWithTP[i].teleport)
            }
        }
    }

    //добавляем цвет телепортам
    func imageTP(_ number: Int) -> SKTexture {
        switch number{
        case 0,1: return SKTexture(imageNamed: "tp1")
        case 2,3: return SKTexture(imageNamed: "tp2")
        default: break
        }
        return SKTexture(imageNamed: "tp1")
    }
    
    //Добавляем монетки
    func addCoins(){
        let numberOfCoins = Int(random(min: 1.0, max: CGFloat(blockCount! * blockCount! / 20)))
        for i in 1...numberOfCoins {
            generateCoin()
            if i < (coins.count - 2) { break }
        }
    }
    func generateCoin(_ i: Int? = nil, j: Int? = nil, child: Bool = false) {
        var a: Int
        var b: Int
        if i != nil &&  j != nil {
            a = i!
            b = j!
        } else {
            repeat {
                a = Int(random(min: 1, max: CGFloat(blockCount!)-1))
                b = Int(random(min: 1, max: CGFloat(blockCount!)-1))
            } while maze![a][b] != 1 || chekCoinPos(a, j: b) || (a == 1 && b == 1)
        }
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.name = "coin"
        coin.zPosition = 5
        coin.size = blockSize!
        coin.position = CGPoint(x: blockSize!.width * CGFloat(b) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(a))
        bg!.addChild(coin)
        
        coins.append((coin: coin, i: a, j: b))
        
        if !child {
            
            if maze![a-1][b] == 1 && !chekCoinPos(a-1, j: b) && random(min: 0, max: 1) > 0.45 {
                generateCoin(a-1, j: b, child: true)
            }
            if maze![a][b-1] == 1 && !chekCoinPos(a, j: b-1) && random(min: 0, max: 1) > 0.45 {
                generateCoin(a, j: b-1, child: true)
            }
            if maze![a+1][b] == 1 && !chekCoinPos(a+1, j: b) && random(min: 0, max: 1) > 0.45 {
                generateCoin(a+1, j: b, child: true)
            }
            if maze![a][b+1] == 1 && !chekCoinPos(a, j: b+1) && random(min: 0, max: 1) > 0.45 {
                generateCoin(a, j: b+1, child: true)
            }
        }
    }
    //Проверяем, есть ли по введённой координате монета (true - есть монета)
    func chekCoinPos(_ i: Int, j: Int) -> Bool {
        for coin in coins {
            if coin.i == i && coin.j == j {
                return true
            }
        }
        return false
    }
    //Проверяем на тупик
    func checkDeadLock(_ positionI: Int, positionJ: Int) -> Bool {
        var sides = (top: true, right: true, bottom: true, left: true)
        if maze![positionI - 1][positionJ] != 0 { sides.top = false }
        if maze![positionI][positionJ + 1] != 0 { sides.right = false }
        if maze![positionI + 1][positionJ] != 0 { sides.bottom = false }
        if maze![positionI][positionJ - 1] != 0 { sides.left = false }
        var a: Int = 0
        var b: Int = 0
        var c: Int = 0
        var d: Int = 0
        if sides.top { a = 1 }
        if sides.right { b = 1 }
        if sides.bottom { c = 1 }
        if sides.left { d = 1 }
        if (a + b + c + d == 3) { return true }
        else { return false }
    }
    
    //Потом удалить (пробник)
    func generateShape2() {
        let atlas: SKTextureAtlas? = SKTextureAtlas(named: "roads")
        var a = 2// колличество декораций, занимающих 1 ячейку
        var a2 = 2// колличество декораций, занимающих 2 ячейки
        for row in 1..<maze!.count-1 {
            let line = maze![row]
            for (col, code) in line.enumerated() {
                var tile: SKNode?
                switch code {
                case 0:
                    addDecor(row, col: col,k: row%a + 1, k2: col%a2 + 1)
                    
                    continue
                case 1:
                    //Тут перерёсток (+)
                    if maze![row][col+1] == 1 && maze![row][col-1] == 1 && maze![row-1][col] == 1 && maze![row+1][col] == 1 { //Дорога везде (перекрёсток +)
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way4"))
                        //tile!.zRotation = Pi / 2
                    }
                    //Тут тройные пересечения (т)
                    else if maze![row][col+1] == 1 && maze![row][col-1] == 1 && maze![row-1][col] == 1 && maze![row+1][col] == 0 { //Дорога везде кроме низа
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way3"))
                        tile!.zRotation = Pi
                    } else if maze![row][col+1] == 1 && maze![row][col-1] == 1 && maze![row-1][col] == 0 && maze![row+1][col] == 1 { //Дорога везде кроме верха
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way3"))
                    } else if maze![row][col+1] == 1 && maze![row][col-1] == 0 && maze![row-1][col] == 1 && maze![row+1][col] == 1 { //Дорога везде кроме лева
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way3"))
                        tile!.zRotation = Pi / 2
                    } else if maze![row][col+1] == 0 && maze![row][col-1] == 1 && maze![row-1][col] == 1 && maze![row+1][col] == 1 { //Дорога везде кроме права
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way3"))
                        tile!.zRotation = Pi * 1.5
                    }
                    //Тут угловые (г)
                    else if maze![row][col+1] == 0 && maze![row][col-1] == 1 && maze![row-1][col] == 0 && maze![row+1][col] == 1 { //Дорога слева и снизу
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way2"))
                        tile!.zRotation = Pi * 1.5
                    } else if maze![row][col+1] == 0 && maze![row][col-1] == 1 && maze![row-1][col] == 1 && maze![row+1][col] == 0 { //Дорога слева и сверху
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way2"))
                        tile!.zRotation = Pi
                    } else if maze![row][col+1] == 1 && maze![row][col-1] == 0 && maze![row-1][col] == 1 && maze![row+1][col] == 0 { //Дорога сверху и справа
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way2"))
                        tile!.zRotation = Pi / 2
                    } else if maze![row][col+1] == 1 && maze![row][col-1] == 0 && maze![row-1][col] == 0 && maze![row+1][col] == 1 { //Дорога снизу и справа
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way2"))
                    }
                   
                    else if maze![row+1][col] != 0 || maze![row-1][col] != 0 { //Дорога вертикальная
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way1"))
                    }
                    //Здесь ошибка too complex, потом это раскоментировать и убрать замену
                    //else if maze![row][col+1] == 1 && maze![row][col-1] == 1 && maze![row-1][col] == 0 && maze![row+1][col] == 0 || maze![row][col+1] == 1 && maze![row][col-1] == 0 && maze![row-1][col] == 0 && maze![row+1][col] == 0 || maze![row][col+1] == 0 && maze![row][col-1] == 1 && maze![row-1][col] == 0 && maze![row+1][col] == 0 { //Дорога горизонтальная
                    else if maze![row][col+1] != 0 || maze![row][col-1] != 0 { //Дорога горизонтальная
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way1"))
                        tile!.zRotation = Pi / 2
                    }
                    else {
                        tile = SKSpriteNode(texture:atlas!.textureNamed("way1"))
                    }
                default:
                    print("Unknown tile code \(code)")
                }
                // 3
                if let sprite = tile as? SKSpriteNode {
                    sprite.size.width = CGFloat(Int(blockSize!.width))
                    sprite.size.height = CGFloat(Int(blockSize!.height))
                }
                tile!.position = CGPoint(x: CGFloat(col) * CGFloat(Int(blockSize!.width)) + CGFloat(Int(blockSize!.width / 2)), y: -CGFloat(row) * CGFloat(Int(blockSize!.height)) - CGFloat(Int(blockSize!.height / 2)))
                tile!.zPosition = 2
                bg!.addChild(tile!)
            }
        }
    }
    
    //функция, которая расставляет декорации
    func addDecor(_ row: Int, col: Int, k: Int,k2: Int){
         let atlas: SKTextureAtlas? = SKTextureAtlas(named: randomScenery)
        let line = maze![row]
        if (maze![row+1][col] == 0 || maze![row-1][col] == 0) && col != 0  && col != (line.count - 1) {
            let randomChanse = random(min: 0, max: 1)
            if randomChanse < 0.2 {
                let tile = SKSpriteNode(texture:atlas!.textureNamed("2-tiles-" + String(k)))
                tile.size = blockSize!
                tile.position = CGPoint(x: CGFloat(col) * blockSize!.width + blockSize!.width / 2, y: -CGFloat(row) * blockSize!.height - blockSize!.height / 2)
                bg!.addChild(tile)
            }
        } else  if col != 0  && col != line.count - 1 {
            let randomChanse = random(min: 0, max: 1)
            if randomChanse < 0.1 {
                let tile = SKSpriteNode(texture:atlas!.textureNamed("1-tile-" + String(k2)))
                tile.size = blockSize!
                tile.position = CGPoint(x: CGFloat(col) * blockSize!.width + blockSize!.width / 2, y: -CGFloat(row) * blockSize!.height - blockSize!.height / 2)
                bg!.addChild(tile)
            }
        }
    }
    
    
    
    //Обводим контур лабиринта
    func generateShape() {
        mazePath.move(to: CGPoint(x: blockSize!.width, y: -blockSize!.height))
        var i = 1
        var j = 2
        var directionPoint = 1 //0-верх, 1-право, 2-низ, 3-лево
        mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
        repeat {
            switch directionPoint {
            case 0:
                if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 3
                } else if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                } else if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                }
            case 1:
                if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                } else if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                } else if maze![i][j - 1] != 0{ // Проверяем низ
                    i = (i+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                }
            case 2:
                if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                } else if maze![i][j - 1] != 0 { // Проверяем низ
                    i = (i+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                } else if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 3
                }
            case 3:
                if maze![i][j - 1] != 0 { // Проверяем низ
                    i = (i+1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                } else if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 3
                } else if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLine(to: CGPoint(x: CGFloat(j) * blockSize!.width, y: CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                }
            default: break
            }
        } while ((i != 1) || (j != 1))
        mazePath.addLine(to: CGPoint(x: blockSize!.width, y: -blockSize!.height))
        mazeShape = SKShapeNode(path: mazePath.cgPath, centered: true)
        mazeShape!.position = CGPoint(x: bg!.frame.width / 2, y: -bg!.frame.height / 2)
        mazeShape!.zPosition = 1
        mazeShape!.fillColor = SKColor.white
        mazeShape!.lineWidth = 0.0
        bg!.addChild(mazeShape!)
    }
    
    //Вызываем когда наступаем на ускорялку
    func useSpeedRoad() {
        kSpeed = 1.7
        speedTimer += 2
        if speedTimer > 10 { speedTimer = 10 }
    }
    //Вызываем когда заканчивается время на ускорялки
    func endUseSpeedRoad() {
        kSpeed = 1
        speedTimer = 0
    }
    
    //Телепортируем плеера к другому телепорту
    func teleportation() {
        if defaults.bool(forKey: "sound") {
            bg!.run(tpSound!)
        }
        print(defaults.bool(forKey: "sound"))
        if (maze![playerPosition.i][playerPosition.j] % 2) == 0 {
            player!.position = arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 19].teleport.position
            teleportExit(arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 19].i, j: arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 19].j)
        } else {
            player!.position = arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 21].teleport.position
            teleportExit(arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 21].i, j: arrayWithTP[Int(maze![playerPosition.i][playerPosition.j]) - 21].j)
        }
    }
    //функция для выхода из телепорта
    func teleportExit(_ i: Int, j: Int) {
        if maze![i - 1][j] != 0 {
            movePlayerDirection = 0
            playerPosition = (i: i - 1, j: j)
            willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
            player!.zRotation = Pi / 2
        } else if maze![i + 1][j] != 0 {
            movePlayerDirection = 2
            playerPosition = (i: i + 1, j: j)
            willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
            player!.zRotation = -Pi / 2
        } else if maze![i][j - 1] != 0 {
            movePlayerDirection = 3
            playerPosition = (i: i, j: j - 1)
            willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
            player!.zRotation = Pi
        } else if maze![i][j + 1] != 0 {
            movePlayerDirection = 1
            playerPosition = (i: i, j: j + 1)
            willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
            player!.zRotation = 0
        }
    }
    
    //ТУПО движется по направлению
    func movePlayer0(_ dt: Double) {
        if player!.position.y > -CGFloat(playerPosition.i) * blockSize!.height - player!.frame.height / 2 {
            playerPosition.i -= 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 4 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 2:
                if defaults.bool(forKey: "sound") && kSpeed != 1.7 {
                    bg!.run(speedUpSound!)
                }
                useSpeedRoad()
            case 4:
                if  kSpeed != 0.2 {
                    if defaults.bool(forKey: "sound") {
                        bg!.run(speedDownSound!)
                    }
                }
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }
            case 20...255:
                break
            default: break
            }
        }
        player!.position.y += playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.y >= willPlayerPosition.y && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer1(_ dt: Double) {
        if player!.position.x > CGFloat(playerPosition.j) * blockSize!.width + player!.frame.width / 2 {
            playerPosition.j += 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 5 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 3:
                if defaults.bool(forKey: "sound") && kSpeed != 1.7 {
                    bg!.run(speedUpSound!)
                }
                useSpeedRoad()
            case 5:
                if  kSpeed != 0.2 {
                    if defaults.bool(forKey: "sound") {
                        bg!.run(speedDownSound!)
                    }
                }
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }
            case 20...255:
                break
            default: break
            }
        }
        player!.position.x += playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.x >= willPlayerPosition.x && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer2(_ dt: Double) {
        if player!.position.y < -CGFloat(playerPosition.i) * blockSize!.height - player!.frame.height / 2 {
            playerPosition.i += 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 2 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 2:
                if  kSpeed != 0.2 {
                    if defaults.bool(forKey: "sound") {
                        bg!.run(speedDownSound!)
                    }
                }
                endUseSpeedRoad()
                kSpeed = 0.2
            case 4:
                if defaults.bool(forKey: "sound") && kSpeed != 1.7 {
                    bg!.run(speedUpSound!)
                }
                useSpeedRoad()
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }            case 20...255:
                break
            default: break
            }
        }
        player!.position.y -= playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.y <= willPlayerPosition.y && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer3(_ dt: Double) {
        if player!.position.x < CGFloat(playerPosition.j) * blockSize!.width + player!.frame.width / 2 {
            playerPosition.j -= 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 3 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 3:
                if  kSpeed != 0.2 {
                    if defaults.bool(forKey: "sound") {
                        bg!.run(speedDownSound!)
                    }
                }
                endUseSpeedRoad()
                kSpeed = 0.2
            case 5:
                if defaults.bool(forKey: "sound") && kSpeed != 1.7 {
                    bg!.run(speedUpSound!)
                }
                useSpeedRoad()
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }            case 20...255:
                break
            default: break
            }
        }
        player!.position.x -= playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.x <= willPlayerPosition.x && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    
    
    //Тупо движемся по направлению (соперник)
    func moveRival0(_ dt: Double) {
        if rivalPlayer!.position.y > -CGFloat(rivalPosition!.i) * blockSize!.height - player!.frame.height / 2 {
            rivalPosition!.i -= 1
            if kSpeed == 0.2 {
                if maze![rivalPosition!.i][rivalPosition!.j] != 4 {
                    kSpeed = 1
                }
            }
            switch maze![rivalPosition!.i][rivalPosition!.j] {
            case 2: useSpeedRoad()
            case 4:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![rivalPosition!.i][rivalPosition!.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }
            case 20...255:
                break
            default: break
            }
        }
        rivalPlayer!.position.y += rivalSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if rivalPlayer!.position.y >= willRivalPosition!.y && maze![rivalPosition!.i][rivalPosition!.j] >= 20 {
            teleportation()
        }
    }
    func moveRival1(_ dt: Double) {
        if rivalPlayer!.position.x > CGFloat(rivalPosition!.j) * blockSize!.width + player!.frame.width / 2 {
            rivalPosition!.j += 1
            if kSpeed == 0.2 {
                if maze![rivalPosition!.i][rivalPosition!.j] != 5 {
                    kSpeed = 1
                }
            }
            switch maze![rivalPosition!.i][rivalPosition!.j] {
            case 3: useSpeedRoad()
            case 5:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![rivalPosition!.i][rivalPosition!.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }
            case 20...255:
                break
            default: break
            }
        }
        rivalPlayer!.position.x += rivalSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки        
        if rivalPlayer!.position.x >= willRivalPosition!.x && maze![rivalPosition!.i][rivalPosition!.j] >= 20 {
            teleportation()
        }
    }
    func moveRival2(_ dt: Double) {
        if rivalPlayer!.position.y < -CGFloat(rivalPosition!.i) * blockSize!.height - player!.frame.height / 2 {
            rivalPosition!.i += 1
            if kSpeed == 0.2 {
                if maze![rivalPosition!.i][rivalPosition!.j] != 2 {
                    kSpeed = 1
                }
            }
            switch maze![rivalPosition!.i][rivalPosition!.j] {
            case 2:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 4: useSpeedRoad()
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![rivalPosition!.i][rivalPosition!.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }            case 20...255:
                break
            default: break
            }
        }
        rivalPlayer!.position.y -= rivalSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if rivalPlayer!.position.y <= willRivalPosition!.y && maze![rivalPosition!.i][rivalPosition!.j] >= 20 {
            teleportation()
        }
    }
    func moveRival3(_ dt: Double) {
        if rivalPlayer!.position.x < CGFloat(rivalPosition!.j) * blockSize!.width + player!.frame.width / 2 {
            rivalPosition!.j -= 1
            if kSpeed == 0.2 {
                if maze![rivalPosition!.i][rivalPosition!.j] != 3 {
                    kSpeed = 1
                }
            }
            switch maze![rivalPosition!.i][rivalPosition!.j] {
            case 3:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 5: useSpeedRoad()
            case 6:
                playTimer = false
                if defaults.bool(forKey: "sound") {
                    bg!.run(timerSound!)
                }
                Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(Maze.switchTimer), userInfo: nil, repeats: false)
                maze![rivalPosition!.i][rivalPosition!.j] = 1
                for (number, i) in stopTimers.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        stopTimers.remove(at: number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerated() {
                    if i.i == rivalPosition!.i && i.j == rivalPosition!.j {
                        i.0.removeFromParent()
                        arrayWithInversions.remove(at: number)
                        break
                    }
                }            case 20...255:
                break
            default: break
            }
        }
        rivalPlayer!.position.x -= rivalSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if rivalPlayer!.position.x <= willRivalPosition!.x && maze![rivalPosition!.i][rivalPosition!.j] >= 20 {
            teleportation()
        }
    }
    
    
    func addInversion(_ count: Int) {
        for i in 0...count-1 {
            let invers = SKSpriteNode(imageNamed: "inversion")
            invers.name = "Invesion"
            invers.size = blockSize!
            invers.zPosition = 4
            var haveInversionBlock = false
            while !haveInversionBlock {
                let randomI: Int = Int(random(min: 0, max: CGFloat(blockCount! - 1)))
                let randomJ: Int = Int(random(min: 0, max: CGFloat(blockCount! - 1)))
                if maze![randomI][randomJ] == 1 {
                    maze![randomI][randomJ] = 7
                    invers.position = CGPoint(x: blockSize!.width * CGFloat(randomJ) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(randomI))
                    arrayWithInversions.append((invers, i: randomI, j: randomJ))
                    bg!.addChild(arrayWithInversions[arrayWithInversions.count - 1].0)
                    haveInversionBlock = true
                }
            }
        }
    }
    
    func inversion() {
        bg!.color = SKColor.white
        mazeShape!.fillColor = SKColor.black
    }
    
    func addWarders(_ count: Int) {
        if warderVariants.count > 0 {
            for i in 0...count-1 {
                let randomWarder = Int(random(min: 0, max: CGFloat(warderVariants.count)))
                var pathLength = 0 //Для пути (в блоках)
                
                switch warderVariants[randomWarder].direction {
                case 0:
                    //Отодвигаем смотрителя в угол, чтобы он не стартовал с середины
                    while maze![warderVariants[randomWarder].i + 1][warderVariants[randomWarder].j] != 0 {
                        warderVariants[randomWarder].i += 2
                    }
                    //Считаем длину его пути
                    while maze![warderVariants[randomWarder].i - pathLength - 1][warderVariants[randomWarder].j] != 0 {
                        pathLength += 1
                    }
                case 1:
                    while maze![warderVariants[randomWarder].i][warderVariants[randomWarder].j - 1] != 0 {
                        warderVariants[randomWarder].j -= 2
                    }
                    while maze![warderVariants[randomWarder].i][warderVariants[randomWarder].j + pathLength + 1] != 0 {
                        pathLength += 1
                    }
                case 2:
                    while maze![warderVariants[randomWarder].i - 1][warderVariants[randomWarder].j] != 0 {
                        warderVariants[randomWarder].i -= 2
                    }
                    while maze![warderVariants[randomWarder].i + pathLength + 1][warderVariants[randomWarder].j] != 0 {
                        pathLength += 1
                    }
                case 3:
                    while maze![warderVariants[randomWarder].i][warderVariants[randomWarder].j + 1] != 0 {
                        warderVariants[randomWarder].j += 2
                    }
                    while maze![warderVariants[randomWarder].i][warderVariants[randomWarder].j - pathLength - 1] != 0 {
                        pathLength += 1
                    }
                default: break
                }
                if warderVariants[randomWarder].i == startBlockPosition.i && warderVariants[randomWarder].j == startBlockPosition.j { //Если смотритель стартует с точки старта плеера, то не добавляем его
                    break
                }
                let warder = SKSpriteNode(imageNamed: "robot")
                warder.size = blockSize!
                warder.name = "warder"
                warder.position = CGPoint(x: blockSize!.width * CGFloat(warderVariants[randomWarder].j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(warderVariants[randomWarder].i))
                warder.zPosition = 6
                bg!.addChild(warder)
                
                //Тут заставляем его двигаться (туда и обратно, так вечно)
                switch warderVariants[randomWarder].direction {
                case 0: warder.run(SKAction.repeatForever(SKAction.sequence([SKAction.run({warder.zRotation = Pi * 0.5}), SKAction.move(by: CGVector(dx: 0, dy: CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8), SKAction.run({warder.zRotation = Pi * 1.5}), SKAction.move(by: CGVector(dx: 0, dy: -CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8)])))
                case 1: print("Вправо")
                    warder.run(SKAction.repeatForever(SKAction.sequence([SKAction.run({warder.zRotation = Pi * 0}), SKAction.moveBy(x: CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8), SKAction.run({warder.zRotation = Pi * 1}), SKAction.moveBy(x: -CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8)])))
                case 2: warder.run(SKAction.repeatForever(SKAction.sequence([SKAction.run({warder.zRotation = Pi * 1.5}), SKAction.move(by: CGVector(dx: 0, dy: -CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8), SKAction.run({warder.zRotation = Pi * 0.5}), SKAction.move(by: CGVector(dx: 0, dy: CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8)])))
                case 3: print("Влево")
                    warder.run(SKAction.repeatForever(SKAction.sequence([SKAction.run({warder.zRotation = Pi * 1}), SKAction.moveBy(x: -CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8), SKAction.run({warder.zRotation = Pi * 0}), SKAction.moveBy(x: CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.wait(forDuration: 0.8)])))
                default: break
                }
                
                warderVariants.remove(at: randomWarder)
            }
        } else {
            print("No warders")
        }
    }
    
    //Проверяем столкновение плеера и смотрителя
    // 0 - ни с чем не столкнулись
    // 1 - столкнулись со смотрителем
    // 2 - взяли монетку
    func checkCollisions() -> Int {
        var result = 0
        bg!.enumerateChildNodes(withName: "warder") { node, _ in
            let ward = node as! SKSpriteNode
            if self.player!.frame.intersects(ward.frame) {
                result = 1
            }
        }
        bg!.enumerateChildNodes(withName: "coin") { node, _ in
            let coin = node as! SKSpriteNode
            //Тут остановился, берёт вместо 1 монеты несколько
            if self.player!.frame.intersects(coin.frame) {
                coin.name = "oldCoin" //Меняем название, чтобы пока монетка уменьшается, мы её мнова не подобрали
                coin.run(SKAction.sequence([SKAction.scale(to: 0.0, duration: 0.3), SKAction.run({coin.removeFromParent()})]))
                //Музыка, когда подобрали монетку
                result = 2
            }
        }
        return result
    }
    
    @objc func switchTimer() {
        playTimer = true
    }
}
