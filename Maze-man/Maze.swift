//
//  Maze.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 13.02.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import SpriteKit

class Maze {
    var maze: [[Int]]? //Массив с блоками
    var blockCount: Int? //Кол-во блоков в строке и столбце
    var actualPoint: (i: Int, j: Int)? //Точка, в которой мы находимся сейчас (для генерации лабиринта)
    var whiteBlocks: [(i: Int, j: Int)] = [] //Все нечётные белые блоки (дорожки)
    var blockSize: CGSize? //Размер одного блока (зависит от размера экрана)
    var deadLocks: [(i: Int, j: Int)] = [] //Координаты всех тупиков
    var arrayWithTP: [(teleport: SKShapeNode, i: Int, j: Int)] = [] //Массив с телепортами
    var arrayWithInversions: [(inversion: SKSpriteNode, i: Int, j: Int)] = [] //Массив с блоками инверсии
    var stopTimers: [(SKSpriteNode, i: Int, j: Int)] = [] //Массив со всеми таймерами на лабиринте
    var startBlockPosition: (i: Int, j: Int)
    var finishBlockPosition: (i: Int, j: Int)
    //Для вывода на экран лабиринта
    var bg: SKSpriteNode?
    var mazeSize: CGSize
    var mazePath = UIBezierPath() //CGPathCreateMutable()
    var mazeShape: SKShapeNode?
    var startBlock: SKShapeNode? //Блок стартаx
    var finishBlock: SKShapeNode? //Блок финиша
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
    
    init(competitiveMod: Bool = true, blockCount: Int, startBlockI: Int = 1, startBlockJ: Int = 1, mazeSize: CGSize? = nil, finishBlockI: Int, finishBlockJ: Int, timer: Int = 0, speedRoads: Bool = false, teleports: Int = 0, inversions: Int = 0, warders: Int = 0) {
        self.blockCount = blockCount
        self.startBlockPosition = (i: startBlockI, j: startBlockJ)
        self.finishBlockPosition = (i: finishBlockI, j: finishBlockJ)
        self.actualPoint = self.startBlockPosition
        if mazeSize == nil {
            self.mazeSize = CGSize(width: blockCount * 30, height: blockCount * 30)
        } else {
            self.mazeSize = mazeSize!
        }
        playerPosition = (i: self.startBlockPosition.i, j: self.startBlockPosition.j)
        whiteBlocks.append((i: startBlockI, j: startBlockI))
        square = [[Bool]](count: blockCount/9 + 1, repeatedValue: [Bool](count: blockCount/9 + 1, repeatedValue: false))
        maze = [[Int]](count: blockCount, repeatedValue: [Int](count: blockCount, repeatedValue: 0))
        
        var playerTextures: [SKTexture] = []
        for i in 1...2 {
            playerTextures.append(SKTexture(imageNamed: "player\(i)"))
        }
        playerAnimation = SKAction.repeatActionForever(SKAction.animateWithTextures(playerTextures, timePerFrame: 0.3))
        
        generateMaze()
        addBg()
        generateShape()
        startAndFinishBlocks()
        playerSettings()
        self.willPlayerPosition = player!.position
        
        if competitiveMod {
            print("CompetitiveMod")
            if timer > 0 { generateTimer(timer) }
            if speedRoads { addSpeedRoads() }
            if teleports > 0 { addTeleport(teleports * 2) }
            if inversions > 0 { addInversion(inversions) }
            if warders > 0 { addWarders(warders) }
            addCoins()
        } else {
            print("FreeMod")
            //По плану сделать столько-то итемов на каждые 100 квадратиков (10х10)
            if timer > 0 { generateTimer(timer) }
            if speedRoads { addSpeedRoads() }
            if teleports > 0 { addTeleport(teleports * 2) }
            if inversions > 0 { addInversion(inversions) }
            if warders > 0 { addWarders(warders) }
        }
    }
    
    func playerSettings() {
        //player = SKShapeNode(rectOfSize: blockSize!)
        player = SKSpriteNode(imageNamed: "player0")
        player!.name = "player"
        player!.size = blockSize!
        player!.position = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
        player!.zPosition = 5
        bg!.addChild(player!)
    }
    
    //Передвигаем плеера по лабиринту
    func movePlayer(direction: Int, playerSpeadChange: Bool) {
        var count = 0
        switch direction {
        case 0:
            player!.zRotation = Pi/2
            if maze![playerPosition.i - 1][playerPosition.j] != 0 {
                print("q0")
                repeat {
                    count += 1
                } while(maze![playerPosition.i - count][playerPosition.j + 1] == 0 && maze![playerPosition.i - count][playerPosition.j - 1] == 0 && maze![playerPosition.i - count - 1][playerPosition.j] != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height + CGFloat(count) * player!.frame.height)
                startPlayerAnimation()
            }
        case 1:
            player!.zRotation = 0
            if maze![playerPosition.i][playerPosition.j + 1] != 0 {
                print("q1")
                repeat {
                    count += 1
                } while(maze![playerPosition.i + 1][playerPosition.j + count] == 0 && maze![playerPosition.i - 1][playerPosition.j + count] == 0 && maze![playerPosition.i][playerPosition.j + count + 1] != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width  + CGFloat(count) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
                startPlayerAnimation()
            }
        case 2:
            player!.zRotation = -Pi/2
            if maze![playerPosition.i + 1][playerPosition.j] != 0 {
                print("q2")
                repeat {
                    count += 1
                } while(maze![playerPosition.i + count][playerPosition.j + 1] == 0 && maze![playerPosition.i + count][playerPosition.j - 1] == 0 && maze![playerPosition.i + count + 1][playerPosition.j] != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height - CGFloat(count) * player!.frame.height)
                startPlayerAnimation()
            }
        case 3:
            player!.zRotation = Pi
            if maze![playerPosition.i][playerPosition.j - 1] != 0 {
                print("q3")
                repeat {
                    count += 1
                } while(maze![playerPosition.i + 1][playerPosition.j - count] == 0 && maze![playerPosition.i - 1][playerPosition.j - count] == 0 && maze![playerPosition.i][playerPosition.j - count - 1] != 0)
                willPlayerPosition = CGPoint(x: player!.frame.width / 2 + CGFloat(playerPosition.j) * player!.frame.width - CGFloat(count) * player!.frame.width, y: -player!.frame.height / 2 - CGFloat(playerPosition.i) * player!.frame.height)
                startPlayerAnimation()
            }
        default: break
        }
        moveResolution = false
        movePlayerDirection = direction
        if playerSpeadChange {
            playerSpeed = sqrt(CGFloat(count)) * blockSize!.width * 2 //Скорость пикселей в секунду
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
                } else if maze![actualPoint!.i + 3][actualPoint!.j] == 1 && (maze![actualPoint!.i + 2][actualPoint!.j + 1] == 1 || maze![actualPoint!.i + 2][actualPoint!.j - 1] == 1) {
                    warderVariants.append((i: actualPoint!.i + 4, j: actualPoint!.j, direction: 0))
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
                } else if maze![actualPoint!.i][actualPoint!.j - 3] == 1 && (maze![actualPoint!.i - 1][actualPoint!.j - 2] == 1 || maze![actualPoint!.i + 1][actualPoint!.j - 2] == 1) {
                    warderVariants.append((i: actualPoint!.i, j: actualPoint!.j - 4, direction: 1))
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
                } else if maze![actualPoint!.i - 3][actualPoint!.j] == 1 && (maze![actualPoint!.i - 2][actualPoint!.j + 1] == 1 || maze![actualPoint!.i - 2][actualPoint!.j - 1] == 1) {
                    warderVariants.append((i: actualPoint!.i - 4, j: actualPoint!.j, direction: 2))
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
                } else if maze![actualPoint!.i][actualPoint!.j + 3] == 1 && (maze![actualPoint!.i - 1][actualPoint!.j + 2] == 1 || maze![actualPoint!.i + 1][actualPoint!.j + 2] == 1) {
                    warderVariants.append((i: actualPoint!.i, j: actualPoint!.j + 4, direction: 3))
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
        for i in 1.stride(to: maze!.count, by: 2) {
            for j in 1.stride(to: maze![0].count, by: 2) {
                if maze![i][j] == 0 {
                    q = true
                    break
                }
            }
        }
        /*for var i = 1; i < maze!.count; i += 2 {
            for var j = 1; j < maze![0].count; j += 2 {
                if maze![i][j] == 0 {
                    q = true
                    break
                }
            }
        }*/
        return q
    }
    //Удаляем белые блоки, которые окружены другими белыми блоками(чтобы не продолжать лабиринт оттуда)
    func checkWhiteBlocks() {
        for (index, i) in whiteBlocks.enumerate() {
            let q = checkSides(i.i, positionJ: i.j)
            if (q.top == false && q.right == false && q.bottom == false && q.left == false) {
                whiteBlocks.removeAtIndex(index)
                checkWhiteBlocks()
                break
            }
        }
    }
    //На чём стоит лабиринт
    func addBg() {
        bg = SKSpriteNode(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), size: CGSize(width: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!, height: Int(Int(self.mazeSize.width) / blockCount!) * blockCount!))
        bg!.position = CGPoint(x: -bg!.frame.width / 2, y: bg!.frame.height / 2)
        bg!.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        blockSize = CGSize(width: bg!.frame.width / CGFloat(blockCount!) , height: bg!.frame.width / CGFloat(blockCount!))
    }
    
    //Даёт плееру анимацию
    func startPlayerAnimation() {
        if player!.actionForKey("playerAnimation") == nil {
            player!.runAction(SKAction.repeatActionForever(playerAnimation), withKey: "playerAnimation")
        }
    }
    //Останавливает анимацию плееру
    func stopPlayerAnimation() {
        player!.removeActionForKey("playerAnimation")
        player!.texture = SKTexture(imageNamed: "player0")
    }
    
    //Выводим на экран старт и финиш
    func startAndFinishBlocks() {
        //Добавляем блок старта
        startBlock = SKShapeNode(rectOfSize: blockSize!)
        startBlock!.lineWidth = 0.0
        startBlock!.fillColor = SKColor.whiteColor()
        startBlock!.position = CGPoint(x: blockSize!.width * CGFloat(startBlockPosition.j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(startBlockPosition.i))
        startBlock?.zPosition = 4
        bg!.addChild(startBlock!)
        //Добавляем блок финиша
        finishBlock = SKShapeNode(rectOfSize: blockSize!)
        finishBlock!.lineWidth = 0.0
        finishBlock!.fillColor = SKColor.redColor()
        finishBlock!.position = CGPoint(x: blockSize!.width * CGFloat(finishBlockPosition.j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(finishBlockPosition.i))
        finishBlock?.zPosition = 4
        bg!.addChild(finishBlock!)
        maze![finishBlockPosition.i][finishBlockPosition.j] = 19
    }
    
    //Проверяем выходит ли точка за рамки массива и свободно ли по сторонам
    func checkSides(positionI: Int, positionJ: Int) -> (top: Bool, right: Bool, bottom: Bool, left: Bool) {
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
                maze![speedRoads[i].i][speedRoads[i].j] = speedRoads[i].direction + 2
                switch speedRoads[i].direction {
                case 0:
                    speedRoads.append((i: speedRoads[i].i - 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i - 1][speedRoads[i].j] = speedRoads[i].direction + 2
                    speedRoads.append((i: speedRoads[i].i - 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i - 2][speedRoads[i].j] = speedRoads[i].direction + 2
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i + 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i + 1][speedRoads[i].j] = speedRoads[i].direction + 2
                        speedRoads.append((i: speedRoads[i].i + 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i + 2][speedRoads[i].j] = speedRoads[i].direction + 2
                    }
                case 1:
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 1, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j + 1] = speedRoads[i].direction + 2
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 2, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j + 2] = speedRoads[i].direction + 2
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 1, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j - 1] = speedRoads[i].direction + 2
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 2, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j - 2] = speedRoads[i].direction + 2
                    }
                case 2:
                    speedRoads.append((i: speedRoads[i].i + 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i + 1][speedRoads[i].j] = speedRoads[i].direction + 2
                    speedRoads.append((i: speedRoads[i].i + 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i + 2][speedRoads[i].j] = speedRoads[i].direction + 2
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i - 1, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i - 1][speedRoads[i].j] = speedRoads[i].direction + 2
                        speedRoads.append((i: speedRoads[i].i - 2, j: speedRoads[i].j, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i - 2][speedRoads[i].j] = speedRoads[i].direction + 2
                    }
                case 3:
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 1, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j - 1] = speedRoads[i].direction + 2
                    speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j - 2, direction: speedRoads[i].direction,backBorder: false))
                    maze![speedRoads[i].i][speedRoads[i].j - 2] = speedRoads[i].direction + 2
                    if speedRoads[i].backBorder {
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 1, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j + 1] = speedRoads[i].direction + 2
                        speedRoads.append((i: speedRoads[i].i, j: speedRoads[i].j + 2, direction: speedRoads[i].direction,backBorder: false))
                        maze![speedRoads[i].i][speedRoads[i].j + 2] = speedRoads[i].direction + 2
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
            for var i = 1; i < maze!.count; i += 2 {
                for var j = 1; j < maze![0].count; j += 2 {
                    if checkDeadLock(i, positionJ: j) {
                        deadLocks.append((i: i, j: j))
                    }
                }
            }
            deadLocks.removeAtIndex(0)
            deadLocks.removeAtIndex(deadLocks.count-1)
        }
    }
    //добалвяем таймер
    func generateTimer(count: Int) {
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
                deadLocks.removeAtIndex(randomDeadLock!)
            }
        }
    }
    // Добавляем телепорт
    func addTeleport(numberTeleports: Int) {
        addDeadLocks() //Заполняем массив с тупиками
        for i in 0...numberTeleports-1 {
            var randomDeadLockForTP: Int
            repeat {
                randomDeadLockForTP = Int(random(min: 0, max: CGFloat(deadLocks.count)))
            } while maze![deadLocks[randomDeadLockForTP].i][deadLocks[randomDeadLockForTP].j] != 1
            maze![deadLocks[randomDeadLockForTP].i][deadLocks[randomDeadLockForTP].j] = 20 + i
            arrayWithTP.append((teleport: SKShapeNode(rectOfSize: blockSize!), i: deadLocks[randomDeadLockForTP].i, j: deadLocks[randomDeadLockForTP].j))
            arrayWithTP[i].teleport.fillColor = fillColorTP(i)
            arrayWithTP[i].teleport.lineWidth = 0.0
            arrayWithTP[i].teleport.position = CGPoint(x: blockSize!.width * CGFloat(deadLocks[randomDeadLockForTP].j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(deadLocks[randomDeadLockForTP].i))
            arrayWithTP[i].teleport.zPosition = 3
            deadLocks.removeAtIndex(randomDeadLockForTP)
            bg!.addChild(arrayWithTP[i].teleport)
        }
    }
    //добавляем цвет телепортам
    func fillColorTP(number: Int) -> SKColor{
        switch number{
        case 0,1: return SKColor.brownColor()
        case 2,3: return SKColor.yellowColor()
        case 3,4: return SKColor.purpleColor()
        case 5,6: return SKColor.orangeColor()
        default: break
        }
        return SKColor.brownColor()
    }
    
    //Добавляем монетки
    func addCoins(){
        let numberOfCoins = Int(random(min: 1.0, max: CGFloat(blockCount! * blockCount! / 20)))
        for i in 1...numberOfCoins {
            generateCoin()
            if i < (coins.count - 2) { break }
        }
    }
    func generateCoin(i: Int? = nil, j: Int? = nil, child: Bool = false) {
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
    func chekCoinPos(i: Int, j: Int) -> Bool {
        for coin in coins {
            if coin.i == i && coin.j == j {
                return true
            }
        }
        return false
    }
    //Проверяем на тупик
    func checkDeadLock(positionI: Int, positionJ: Int) -> Bool {
        var sides = (top: true, right: true, bottom: true, left: true)
        if maze![positionI - 1][positionJ] != 0 { sides.top = false }
        if maze![positionI][positionJ + 1] != 0 { sides.right = false }
        if maze![positionI + 1][positionJ] != 0 { sides.bottom = false }
        if maze![positionI][positionJ - 1] != 0 { sides.left = false }
        if (Int(sides.top) + Int(sides.right) + Int(sides.bottom) + Int(sides.left) == 3) { return true }
        else { return false }
    }
    
    //Обводим контур лабиринта
    func generateShape() {
        mazePath.moveToPoint(CGPointMake(blockSize!.width, -blockSize!.height))
        // CGPathMoveToPoint(mazePath, nil, blockSize!.width, -blockSize!.height)
        var i = 1
        var j = 2
        var directionPoint = 1 //0-верх, 1-право, 2-низ, 3-лево
        mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
        repeat {
            switch directionPoint {
            case 0:
                if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    //CGPathAddLineToPoint(mazePath, nil, CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height)
                    directionPoint = 3
                } else if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                } else if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                }
            case 1:
                if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                } else if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                } else if maze![i][j - 1] != 0{ // Проверяем низ
                    i = (i+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                }
            case 2:
                if maze![i][j] != 0 { // Проверяем право
                    j = (j+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 1
                } else if maze![i][j - 1] != 0 { // Проверяем низ
                    i = (i+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                } else if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 3
                }
            case 3:
                if maze![i][j - 1] != 0 { // Проверяем низ
                    i = (i+1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 2
                } else if maze![i-1][j-1] != 0 { // Проверяем лево
                    j = (j-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 3
                } else if maze![i - 1][j] != 0 { //Проверяем верх
                    i = (i-1)
                    mazePath.addLineToPoint(CGPointMake(CGFloat(j) * blockSize!.width, CGFloat(-i) * blockSize!.height))
                    directionPoint = 0
                }
            default: break
            }
        } while ((i != 1) || (j != 1))
        mazePath.addLineToPoint(CGPointMake(blockSize!.width, -blockSize!.height))
        mazeShape = SKShapeNode(path: mazePath.CGPath, centered: true)
        mazeShape!.position = CGPoint(x: bg!.frame.width / 2, y: -bg!.frame.height / 2)
        mazeShape!.zPosition = 1
        mazeShape!.fillColor = SKColor.whiteColor()
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
        if (maze![playerPosition.i][playerPosition.j] % 2) == 0 {
            player!.position = arrayWithTP[maze![playerPosition.i][playerPosition.j] - 19].teleport.position
            teleportExit(arrayWithTP[maze![playerPosition.i][playerPosition.j] - 19].i, j: arrayWithTP[maze![playerPosition.i][playerPosition.j] - 19].j)
        } else {
            player!.position = arrayWithTP[maze![playerPosition.i][playerPosition.j] - 21].teleport.position
            teleportExit(arrayWithTP[maze![playerPosition.i][playerPosition.j] - 21].i, j: arrayWithTP[maze![playerPosition.i][playerPosition.j] - 21].j)
        }
    }
    //функция для выхода из телепорта
    func teleportExit(i: Int, j: Int) {
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
    func movePlayer0(dt: Double) {
        if player!.position.y > -CGFloat(playerPosition.i) * blockSize!.height - player!.frame.height / 2 {
            playerPosition.i -= 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 4 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 2: useSpeedRoad()
            case 4:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("switchTimer"), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.removeAtIndex(number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.removeAtIndex(number)
                        break
                    }
                }            case 20...999:
                break
            default: break
            }
        }
        player!.position.y += playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.y >= willPlayerPosition.y && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer1(dt: Double) {
        if player!.position.x > CGFloat(playerPosition.j) * blockSize!.width + player!.frame.width / 2 {
            playerPosition.j += 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 5 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 3: useSpeedRoad()
            case 5:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 6:
                playTimer = false
                NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("switchTimer"), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.removeAtIndex(number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.removeAtIndex(number)
                        break
                    }
                }
            case 20...999:
                break
            default: break
            }
        }
        player!.position.x += playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.x >= willPlayerPosition.x && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer2(dt: Double) {
        if player!.position.y < -CGFloat(playerPosition.i) * blockSize!.height - player!.frame.height / 2 {
            playerPosition.i += 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 2 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 2:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 4: useSpeedRoad()
            case 6:
                playTimer = false
                NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("switchTimer"), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.removeAtIndex(number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.removeAtIndex(number)
                        break
                    }
                }            case 20...999:
                break
            default: break
            }
        }
        player!.position.y -= playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.y <= willPlayerPosition.y && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    func movePlayer3(dt: Double) {
        if player!.position.x < CGFloat(playerPosition.j) * blockSize!.width + player!.frame.width / 2 {
            playerPosition.j -= 1
            if kSpeed == 0.2 {
                if maze![playerPosition.i][playerPosition.j] != 3 {
                    kSpeed = 1
                }
            }
            switch maze![playerPosition.i][playerPosition.j] {
            case 3:
                endUseSpeedRoad()
                kSpeed = 0.2
            case 5: useSpeedRoad()
            case 6:
                playTimer = false
                NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("switchTimer"), userInfo: nil, repeats: false)
                maze![playerPosition.i][playerPosition.j] = 1
                for (number, i) in stopTimers.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        stopTimers.removeAtIndex(number)
                        break
                    }
                }
            case 7:
                inversion() //Инверсия
                for (number, i) in arrayWithInversions.enumerate() {
                    if i.i == playerPosition.i && i.j == playerPosition.j {
                        i.0.removeFromParent()
                        arrayWithInversions.removeAtIndex(number)
                        break
                    }
                }            case 20...999:
                /*print(player!.position.y , willPlayerPosition.y)
                if player!.position.x <= CGFloat(playerPosition.j) * blockSize!.width + player!.frame.width / 2 + playerSpeed! * CGFloat(dt) * kSpeed {
                    teleportation()
                }*/
                break
            default: break
            }
        }
        player!.position.x -= playerSpeed! * CGFloat(dt) * kSpeed //kSpeed - коэффициент от ускорялки
        
        if player!.position.x <= willPlayerPosition.x && maze![playerPosition.i][playerPosition.j] >= 20 {
            teleportation()
        }
    }
    
    func addInversion(count: Int) {
        for i in 0...count-1 {
            let invers = SKSpriteNode(imageNamed: "inversion")
            invers.name = "Invesion"
            invers.size = blockSize!
            invers.zPosition = 4
            var haveInversionBlock = false
            while !haveInversionBlock {
                var randomI: Int = Int(random(min: 0, max: CGFloat(blockCount! - 1)))
                var randomJ: Int = Int(random(min: 0, max: CGFloat(blockCount! - 1)))
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
        bg!.color = SKColor.whiteColor()
        mazeShape!.fillColor = SKColor.blackColor()
    }
    
    //Тут остановился. Надо расчитать длину пути смотрителя, чтобы он мог передвигаться по координатам (runAction)
    func addWarders(count: Int) {
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
                
                let warder = SKSpriteNode(color: UIColor.orangeColor(), size: blockSize!)
                warder.name = "warder"
                warder.position = CGPoint(x: blockSize!.width * CGFloat(warderVariants[randomWarder].j) + blockSize!.width / 2, y: -blockSize!.height / 2 - blockSize!.height * CGFloat(warderVariants[randomWarder].i))
                warder.zPosition = 6
                bg!.addChild(warder)
                
                //Тут заставляем его двигаться (туда и обратно, так вечно)
                switch warderVariants[randomWarder].direction {
                case 0: warder.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.moveBy(CGVector(dx: 0, dy: CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8), SKAction.moveBy(CGVector(dx: 0, dy: -CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8)])))
                case 1: print("Вправо")
                    warder.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.moveByX(CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8), SKAction.moveByX(-CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8)])))
                case 2: warder.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.moveBy(CGVector(dx: 0, dy: -CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8), SKAction.moveBy(CGVector(dx: 0, dy: CGFloat(pathLength) * blockSize!.height), duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8)])))
                case 3: print("Влево")
                    warder.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.moveByX(-CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8), SKAction.moveByX(CGFloat(pathLength) * blockSize!.width, y: 0, duration: 0.5 * Double(pathLength)), SKAction.waitForDuration(0.8)])))
                default: break
                }
                //warder.runAction(SKAction.repeatActionForever(SKAction.sequence([])))
                
                warderVariants.removeAtIndex(randomWarder)
            }
        } else {
            print("fail")
        }
    }
    
    //Проверяем столкновение плеера и смотрителя
    // 0 - ни с чем не столкнулись
    // 1 - столкнулись со смотрителем
    // 2 - взяли монетку
    func checkCollisions() -> Int {
        var result = 0
        bg!.enumerateChildNodesWithName("warder") { node, _ in
            let ward = node as! SKSpriteNode
            if CGRectIntersectsRect(self.player!.frame, ward.frame) {
                result = 1
            }
        }
        bg!.enumerateChildNodesWithName("coin") { node, _ in
            let coin = node as! SKSpriteNode
            if CGRectIntersectsRect(self.player!.frame, coin.frame) {
                coin.removeFromParent()
                result = 2
            }
        }
        return result
    }
    
    @objc func switchTimer() {
        playTimer = true
    }
}