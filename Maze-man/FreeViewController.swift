//
//  FreeViewController.swift
//  Maze-man
//
//  Created by Chekunin Alexey on 08.03.16.
//  Copyright © 2016 Chekunin Alexey. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit
import Foundation

class FreeViewController: UIViewController, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
//class FreeViewController: UIViewController {
    var scene: Free?
    var matchmakerViewController: GKMatchmakerViewController?
    var match: GKMatch? //Здесь хранится сам наш матч
    var iAmHost: Bool = false //Наш телефон сервер или нет
    var haveMaze: Bool = false //Получили ли мы лабиринт от соперника
    var haveRivalInfo: Bool = false //Получили ли мы от соперника информацию (скин, скорость и т.д.)
    
    @IBOutlet weak var loadingView: UIView? //Для экрана загрузки мультиплеера
    
    override func loadView() {
        self.view = SKView(frame: UIScreen.main.applicationFrame)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(FreeViewController.mPlayer), name: NSNotification.Name("mult player"), object: nil)
        
        super.viewDidLoad()
        let skView = self.view as! SKView
        var size = skView.bounds.size
        size.width *= 2
        size.height *= 2
        scene = Free(size: size)
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        scene!.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Вызываем окно для поиска игроков в мультиплеере
    func mPlayer() {
        print("12345")
        let asd: GKMatchRequest = GKMatchRequest()
        asd.minPlayers = 2
        asd.maxPlayers = 2
        asd.defaultNumberOfPlayers = 2
        asd.inviteMessage = "Привет. Го катать!"
        
        matchmakerViewController = GKMatchmakerViewController(matchRequest: asd)
        matchmakerViewController!.matchmakerDelegate = self
        self.present(matchmakerViewController!, animated: true, completion: nil)
    }
    //GKMatchmakerViewControllerDelegate
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) { //Когда отменяем поиск
        print("Убираем это окно")
        viewController.dismiss(animated: true, completion: nil)
        viewController.navigationController?.popViewController(animated: true)
    }
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) { //Когда происходит какая-то ошибка
        viewController.dismiss(animated: true, completion: nil)
        NSLog("Error finding match: \(error.localizedDescription)")
    }
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) { //Когда все подключились и готовы играть
        resetAllVars() //Обнуляем все старые значения (если остались с прошлой игры)
        self.match = match
        scene!.match = match
        self.match!.delegate = self
        if match.expectedPlayerCount == 0 { //Если все поключились
            //Здесь мы отображаем экран загрузки игры (чёрный фон с надписью Loading...)
            loadingView!.isHidden = false
            SwiftSpinner.show(title: "Loading", animated: true)
            viewController.dismiss(animated: true, completion: nil)
            //self.match!.chooseBestHostingPlayer(completionHandler: foundBestHostingPlayer)
            determineHost()
            //Узнаём ник нашего противника
            for player in match.players {
                if player.playerID != GKLocalPlayer.localPlayer().playerID {
                    scene!.rivalName = player.displayName!
                }
            }
            print("Играем!!!")
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case GKPlayerConnectionState.stateConnected:
            print(player.displayName, " подключился к игре")
        case GKPlayerConnectionState.stateDisconnected:
            if scene!.iLeft {
                print("Я покинул игру (и проиграл)")
                scene!.upperLayer!.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height / 2)
                scene!.upperLayer!.isHidden = false
                scene!.bgBasic?.removeFromParent()
                scene!.exitButton.isHidden = true
                scene!.winnerBg?.isHidden = true
            } else {
                print(player.displayName!, " отключился")
                scene!.iAmWinner = true
                scene!.showWinnerBg() //Показываем экран с победителем
                //Показываем статус, что противник отключился
                scene!.infoLabel?.fontColor = UIColor.red
                scene!.infoLabel?.text = player.displayName! + " покинул игру."
                scene!.infoLabel?.isHidden = false
                scene!.playMoreButton.alpha = 0.5
            }
        default: break
        }
    }
    
    func match(_ match: GKMatch, didReceiveData data: NSData, fromRemotePlayer player: GKPlayer) {
        //Первое что мы должны получить - массив лабиринта
        if !haveMaze {
            //scene!.maze!.bg?.removeFromParent()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            /*if scene?.maze?.bg != nil {
                scene!.maze!.bg!.removeFromParent()
            }*/
            scene!.maze?.bg?.removeFromParent()
            scene!.makeMaze()
            var receivedMaze: [UInt8] = [UInt8](repeating: 0, count: scene!.maze!.blockCount! * scene!.maze!.blockCount!)
            let dataa: Data = data as Data
            dataa.copyBytes(to: &receivedMaze, count: scene!.maze!.blockCount! * scene!.maze!.blockCount!)
            print("Массив с лабиринтом принят")
            haveMaze = true
            print("Лабиринт построен")
            print(receivedMaze)
            print(receivedMaze.count)
            scene!.maze!.maze!.removeAll()
            scene!.maze!.maze = []
            for i in 0..<receivedMaze.count {
                if i % scene!.maze!.blockCount! == 0 {
                    scene!.maze!.maze!.append([])
                }
                scene!.maze!.maze![i / scene!.maze!.blockCount!] += [receivedMaze[i]]
            }
            scene!.maze!.printMaze()
            scene!.maze!.startForMultiGame()
            if scene!.bgBasic == nil {
                scene!.addBg()
            } else { scene!.bgBasic!.position = CGPoint(x: 0, y: scene!.size.height) }
            scene!.bgBasic!.addChild(scene!.maze!.bg!)
            
            if scene!.upperLayer!.isHidden == false {
                scene!.upperLayer!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                    self.scene!.upperLayer!.isHidden = true
                    self.scene!.exitButton.isHidden = false
                    self.scene!.stopPlaying = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                })]))
            } else if scene!.winnerBg?.isHidden == false {
                scene!.hideWinnerBg() //Убираем winnerBg
            }
        } else if !haveRivalInfo {
            loadingView!.isHidden = true
            SwiftSpinner.hide()
            var receivedPocket: [UInt8] = [0,0] //1-ый - скин, 2-ой - скорость
            let dataa: Data = data as Data
            dataa.copyBytes(to: &receivedPocket, count: 2)
            //Подбираем скин (позже доделать)
            switch receivedPocket[0] {
            default: break
            }
            //Ставим нужную скорость соперника
            scene!.maze!.rivalSpeedK = CGFloat(receivedPocket[1])
            haveRivalInfo = true
            //Убираем экран загрузки
            print("Убираем экран загрузки")
        } else {
            var receivedPocket: [UInt8] = [0,0,0]
            let dataa: Data = data as Data
            dataa.copyBytes(to: &receivedPocket, count: dataa.count)
            switch receivedPocket[0] {
            case 0: print("Соперник - Вверх") //Соперник пошёл вверх
                scene!.maze!.moveRival(0, playerSpeadChange: true)
            case 1: print("Соперник - Вправо") //Соперник пошёл вправо
                scene!.maze!.moveRival(1, playerSpeadChange: true)
            case 2: print("Соперник - Вниз") //Соперник пошёл вниз
                scene!.maze!.moveRival(2, playerSpeadChange: true)
            case 3: print("Соперник - Влево") //Соперник пошёл влево
                scene!.maze!.moveRival(3, playerSpeadChange: true)
            case 4:
                scene!.maze!.rivalPosition!.i = Int(receivedPocket[1])
                scene!.maze!.rivalPosition!.j = Int(receivedPocket[2])
                scene!.maze!.rivalPlayer!.position = CGPoint(x: CGFloat(scene!.maze!.rivalPosition!.j) * scene!.maze!.blockSize!.width + scene!.maze!.rivalPlayer!.frame.width / 2, y: -CGFloat(scene!.maze!.rivalPosition!.i) * scene!.maze!.blockSize!.height - scene!.maze!.rivalPlayer!.frame.height / 2)
            case 5: print("Соперник победил! :(")
                scene!.stopPlaying = true //Останавливаем игру, противник то уже на финише
                scene!.rivalWantPlayMore = nil //Обнуляем данные
                scene!.iWantPlayMore = false
                self.scene!.winnerBg?.removeFromParent() //Удаляем весь этот фон, так как потом мы его снова добавляем
                self.scene!.winnerBg = nil
                scene!.showWinnerBg()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode Off"), object: self)
            case 6: print("Соперник предлагает сыграть ещё раз")
                if !scene!.iWantPlayMore {
                    scene!.infoLabel!.isHidden = false
                    scene!.infoLabel!.text = match.players[0].displayName! + " предлагает сыграть ещё раз."
                    scene!.infoLabel!.fontColor = UIColor.green
                }
                scene!.rivalWantPlayMore = true
                haveRivalInfo = false //Мало ли за это время плеер успел что-то изменить (скорость, скин)
                haveMaze = false
                if scene!.iAmHost {
                    haveMaze = true
                    //NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                    if scene!.iWantPlayMore == true {
                        scene!.forBestHost()
                    }
                }
                //должен появляться Label типа противник хочет ещё разок сыграть
            default: break
            }
            //Если мы получили лабиринт и инфу о противнике, то дальше получаем по байту по ходу игры (направление, на финише и .д.)
            /*
            0 - идём вверх
            1 - идём направо
            2 - идёи вниз
            3 - идём влево
            4 - противник на повороте остановился, получаем его позицию
            5 - противник на финише (он победил - мы проиграли)
            6 - противник хочет сыграть ещё раз
            */
            
        }
    }
    
    //Определяем хоста (почти рандомно)
    func determineHost() {
        print("I'm: ", GKLocalPlayer.localPlayer().playerID!)
        print("Rival is: ", self.match!.players[0].playerID!)
        if GKLocalPlayer.localPlayer().playerID! > self.match!.players[0].playerID! {
            print(GKLocalPlayer.localPlayer().displayName, " выбран сервером игры")
            scene!.iAmHost = true
            scene!.forBestHost()
            haveMaze = true
        }
    }
    
    
    //Обнуляем все переменные для следующего мультиплеера
    func resetAllVars() {
        match = nil
        iAmHost = false
        haveMaze = false
        haveRivalInfo = false
        
        scene!.maze = nil
        scene!.bgBasic = nil
        scene!.oldFingerPosition = nil
        scene!.resolution = false
        scene!.stopPlaying = true
        
        scene!.iAmWinner = false
        
        scene!.match = nil
        scene!.iAmHost = false
        scene!.rivalWantPlayMore = nil
        scene!.iWantPlayMore = false
        scene!.iLeft = false
    }
    
    
    
    
    
    //Это уже не успользуем
    func foundBestHostingPlayer(player: GKPlayer?) {
        if let bestHosting = player {
            print(player!.displayName!, " выбран сервером игры")
            //scene!.match = match
            if player!.playerID! == GKLocalPlayer.localPlayer().playerID! {
                scene!.iAmHost = true
                scene!.forBestHost()
                haveMaze = true
            } else {
                scene!.iAmHost = false
            }
        }  else {
            print("Не удалось определить сервер игры")
            print("поэтому...это сделает рандом")
            print("I'm: ", GKLocalPlayer.localPlayer().playerID!)
            print("Rival is: ", self.match!.players[0].playerID!)
            //scene!.match = match
            if GKLocalPlayer.localPlayer().playerID! > self.match!.players[0].playerID! {
                print(GKLocalPlayer.localPlayer().displayName, " выбран сервером игры")
                scene!.iAmHost = true
                scene!.forBestHost()
                haveMaze = true
            }
        }
    }
    
    /*func forBestHost(player: GKPlayer) {
        print(player.displayName!, " выбран сервером игры")
        if player.playerID! == GKLocalPlayer.localPlayer().playerID! {
            scene!.maze!.bg?.removeFromParent()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            
            iAmHost = true
            scene!.iAmHost = true
            //Генерируем лабиринт
            scene!.makeMaze(self.match!)
            scene!.maze!.generateMaze()
            var mazeArray: [UInt8] = []
            //Дмумерный массив лабиринта объединяем в одинарный
            for i in scene!.maze!.maze! {
                mazeArray += i
            }
            //Отправляем массив с лабиринтом сопернику
            do {
                try self.match!.sendData(toAllPlayers: NSData(bytes: &mazeArray, length: mazeArray.count) as Data, with: GKMatchSendDataMode.reliable)
            } catch {
                print("Some error in sendData")
            }
            print("Массив с лабиринтом отправлен")
            haveMaze = true
            print("Лабиринт построен")
            scene!.maze!.startForMultiGame() //Отправляем свой скин и скорость сопернику, также прорисоываем у себя лабиринт
            scene!.addBg()
            scene!.bgBasic!.addChild(scene!.maze!.bg!)
            
            /*scene!.upperLayer!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                self.scene!.upperLayer!.isHidden = true
                self.scene!.stopPlaying = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
            })]))*/
            if scene!.upperLayer!.isHidden == false {
                scene!.upperLayer!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                    self.scene!.upperLayer!.isHidden = true
                    self.scene!.stopPlaying = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                })]))
            } else if scene!.winnerBg?.isHidden == false {
                scene!.winnerBg!.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: -scene!.size.height), duration: 0.6), SKAction.run({
                    self.scene!.winnerBg!.isHidden = true
                    self.scene!.stopPlaying = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "game mode On"), object: self)
                })]))
            }
        } else { iAmHost = false }
    } */
}
