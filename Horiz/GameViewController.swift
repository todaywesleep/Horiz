//
//  GameViewController.swift
//  Horiz
//
//  Created by Vladislav Erchik on 9.03.21.
//

import UIKit
import SceneKit
import SpriteKit
import CoreGraphics

class GameViewController: UIViewController {
    override var shouldAutorotate: Bool { false }
    override var prefersStatusBarHidden: Bool { true }
    private var startedCreateSequence = false
    
    let categoryTree = 2
    
    var sceneView: SCNView!
    var scene: SCNScene!
    
    var ballNode: SCNNode!
    var selfieStickNode: SCNNode!
    
    var currentTile: SCNNode!
    var currentTileIndex: (i: Int, j: Int) = (0, 0)
    var nearbyTiles = [[SCNNode]]()
    /// Square matrix of tiles size
    var dimension: Int = 7
    
    var motion = MotionHelper()
    var motionForce = SCNVector3(x: 0, y: 0, z: 0)
    
    var sounds: [String: SCNAudioSource] = [:]
    let floor = SCNScene(named: "art.scnassets/TileScene.scn")!.rootNode
        .childNode(withName: "tile", recursively: true)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    func setupScene() {
        sceneView = (self.view as! SCNView)
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        scene.physicsWorld.contactDelegate = self
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        
        tapRecognizer.addTarget(self, action: #selector(sceneTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    func setupNodes() {
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)!
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)!
        currentTile = scene.rootNode.childNode(withName: "tile", recursively: true)!
        
        ballNode.physicsBody?.contactTestBitMask = categoryTree
        prepareFloor()
//        ballNode.physicsBody?.contactTestBitMask = categoryTree | categoryRock
    }
    
    func setupSounds() {
        let sawSound = SCNAudioSource(fileNamed: "chain.wav")!
        let jumpSound = SCNAudioSource(fileNamed: "jump.wav")!
        let backgroundsSound = SCNAudioSource(fileNamed: "bckg.mp3")!
        backgroundsSound.loops = true
        
        sawSound.load()
        jumpSound.load()
        backgroundsSound.load()
        
        sawSound.volume = 0.3
        jumpSound.volume = 0.4
        backgroundsSound.volume = 0.1
        
        sounds["saw"] = sawSound
        sounds["jump"] = jumpSound
        
        let player = SCNAudioPlayer(source: backgroundsSound)
        ballNode.addAudioPlayer(player)
    }
    
    @objc func sceneTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        guard hitResults.count > 0 else { return }
        
//        let node = hitResults.first?.node
//        node.name == "ball"
        let jumpSound = sounds["jump"]!
        ballNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
        let newVector = SCNVector3(
            ballNode.presentation.position.x,
            ballNode.presentation.position.y + 15,
            ballNode.presentation.position.z
        )
        ballNode.physicsBody?.applyForce(.init(0, 5, -4), at: newVector, asImpulse: true)
//        ballNode.physicsBody?.applyForce(SCNVector3(x: 0, y: 15, z: 5), asImpulse: true)
    }
    
    private let tileDrawDistance = 3
    private func prepareFloor() {
        if nearbyTiles.isEmpty {
            let bounding = currentTile.boundingBox
            let size = bounding.max.x - bounding.min.x
            let halfSize = size / 2
            let tileNode = SCNScene(named: "art.scnassets/TileScene.scn")!.rootNode
                .childNode(withName: "tile", recursively: true)!
            
            var count = 1
            for i in 1...tileDrawDistance {
                count += 8 * i
            }
            dimension = Int(sqrt(Double(count)))
            for _ in 0..<dimension { nearbyTiles.append([]) }
            var actions = [SCNAction]()
            
            for i in 0..<dimension {
                for j in 0..<dimension {
                    let x: Float = bounding.min.x - halfSize
                    let z = bounding.min.y - halfSize
                    
                    let addAction = SCNAction.run({ node in
                        let color = UIColor(
                            red: CGFloat.random(in: 0...1),
                            green: CGFloat.random(in: 0...1),
                            blue: CGFloat.random(in: 0...1),
                            alpha: 1
                        )
                        
                        let nodeToAdd = tileNode.flattenedClone()
                        nodeToAdd.geometry = tileNode.geometry!.copy() as? SCNGeometry
                        nodeToAdd.geometry?.firstMaterial = tileNode.geometry!.firstMaterial!.copy() as? SCNMaterial
                        
                        nodeToAdd.geometry?.firstMaterial?.diffuse.contents = color
                        node.addChildNode(nodeToAdd)
                        let position = SCNVector3(
                            x: x * Float(j) + (size * Float(self.tileDrawDistance)),
                            y: 0,
                            z: z * Float(i) + (size * Float(self.tileDrawDistance))
                        )
                        nodeToAdd.position = position
                        
                        print("[TEST] Postion: \(position)")
                        self.nearbyTiles[i].append(nodeToAdd)
                    })
                    
                    actions.append(addAction)
                }
            }
            
            scene.rootNode.runAction(SCNAction.sequence(actions)) {
                let currentIndex = self.tileDrawDistance
                self.nearbyTiles[self.tileDrawDistance][self.tileDrawDistance] = self.currentTile
                self.currentTileIndex = (currentIndex, currentIndex)
                self.floorPrepared = true
            }
        }
    }
    
    private var floorPrepared = false
    private var isProcessingTile = false
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let ball = ballNode.presentation
        let ballPosition = ball.position
        let tilePosition = currentTile.presentation.position
        let tileSize = currentTile.presentation.boundingBox.max.x - currentTile.presentation.boundingBox.min.x
        
        print("[TEST] Position ball: \(self.ballNode.presentation.position)")
        if floorPrepared {
            if ballPosition.z > tilePosition.z + tileSize / 2 {
                processTileLeft(tile: self.nearbyTiles[tileDrawDistance - 1][tileDrawDistance])
            } else if ballPosition.z < tilePosition.z - tileSize / 2 {
                processTileLeft(tile: self.nearbyTiles[tileDrawDistance + 1][tileDrawDistance])
            } else if ballPosition.x > tilePosition.x + tileSize / 2 {
                processTileLeft(tile: self.nearbyTiles[tileDrawDistance][tileDrawDistance - 1])
            } else if ballPosition.x < tilePosition.x - tileSize / 2 {
                processTileLeft(tile: self.nearbyTiles[tileDrawDistance][tileDrawDistance + 1])
            }
            
        }
        
        let targetPosition = SCNVector3(
            x: ballPosition.x,
            y: ballPosition.y + 5,
            z: ballPosition.z + 5
        )
        
        var cameraPosition = selfieStickNode.position
        let camDamping: Float = 0.3
        
        let xComponent = cameraPosition.x * (1 - camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1 - camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1 - camDamping) + targetPosition.z * camDamping
        
        cameraPosition = SCNVector3(x: xComponent, y: yComponent, z: zComponent)
        selfieStickNode.position = cameraPosition

//        self.motionForce = SCNVector3(
//            x: 10,
//            y: 0,
//            z: -10
//        )
//
//        ballNode.physicsBody?.velocity = motionForce
        motion.getAccelerometerData { (x, y, z) in
            self.motionForce = SCNVector3(x: x * 0.05, y: 0, z: (y + 0.3) * -0.05)
        }

        ballNode.physicsBody?.velocity += motionForce
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.name == "tree" || nodeB.name == "tree" {
            processTreeCollision(tree: nodeA.name == "tree" ? nodeA : nodeB)
        }
    }
    
    private func processTileLeft(tile: SCNNode) {
        var i: Int = currentTileIndex.i
        var j: Int = currentTileIndex.j
        
        for (iIndex, tileArray) in nearbyTiles.enumerated() {
            if let index = tileArray.firstIndex(of: tile) {
                i = iIndex
                j = index
                
                break
            }
        }
        
        if !isProcessingTile {
            processTileAdding(newIndex: (i, j))
        }
    }
    
    private func processTileAdding(newIndex: (i: Int, j: Int)) {
        let diff: Int
        let origin: Int
        let isVertical: Bool
        
        if currentTileIndex.i != newIndex.i {
            diff = newIndex.i
            origin = currentTileIndex.i
            isVertical = true
        } else if currentTileIndex.j != newIndex.j {
            diff = newIndex.j
            origin = currentTileIndex.j
            isVertical = false
        } else { return }
        
        isProcessingTile = true
        print("[TEST] Origin: \(origin), diff: \(diff)")
        let bounding = currentTile.boundingBox
        let size = bounding.max.x - bounding.min.x
        let isNegativeDeviation = origin < diff
        let indexToRemove = isNegativeDeviation ? 0 : dimension - 1
        var indexToAdd = isNegativeDeviation ? dimension - 1 : 0
        let normalizer = isNegativeDeviation ? -1 : 1
        let sizeNormalizer = isNegativeDeviation ? -size : size

        for i in 0..<self.dimension {
            self.nearbyTiles[isVertical ? indexToRemove : i][isVertical ? i : indexToRemove]
                .removeFromParentNode()
        }
        if isVertical {
            self.nearbyTiles.remove(at: indexToRemove)
            self.nearbyTiles.insert([], at: indexToAdd)
        } else {
            for i in 0..<self.dimension {
                self.nearbyTiles[i].remove(at: indexToRemove)
            }
        }
        indexToAdd += normalizer

        let addAction = SCNAction.run({ node in
            for i in 0..<self.dimension {
                let floorCopy = self.floor.clone()
                let color = UIColor(
                    red: CGFloat.random(in: 0...1),
                    green: CGFloat.random(in: 0...1),
                    blue: CGFloat.random(in: 0...1),
                    alpha: 1
                )

                floorCopy.geometry = self.floor.geometry!.copy() as? SCNGeometry
                floorCopy.geometry?.firstMaterial = self.floor.geometry!.firstMaterial!.copy() as? SCNMaterial
                floorCopy.geometry?.firstMaterial?.diffuse.contents = color

                let targetTile = self.nearbyTiles[isVertical ? indexToAdd : i][isVertical ? i : indexToAdd]
                let position = SCNVector3(
                    x: isVertical
                        ? self.nearbyTiles[indexToAdd][i].position.x
                        : targetTile.position.x + sizeNormalizer,
                    y: 0,
                    z: isVertical
                        ? targetTile.position.z + sizeNormalizer
                        : self.nearbyTiles[i][indexToAdd].position.z
                )
                
                floorCopy.position = position
                
                if isVertical {
                    self.nearbyTiles[indexToAdd - normalizer].append(floorCopy)
                } else {
                    self.nearbyTiles[i].insert(floorCopy, at: indexToAdd - normalizer)
                }
                node.addChildNode(floorCopy)
            }
            
            self.isProcessingTile = false
        }, queue: .main)

        self.scene.rootNode.runAction(addAction) {
            self.currentTile = self.nearbyTiles[self.currentTileIndex.i][self.currentTileIndex.j]
        }
    }
    
    private func processTreeCollision(tree: SCNNode) {
        if tree.physicsBody?.categoryBitMask == categoryTree {
            let action = SCNAction.run({ node in
                node.removeFromParentNode()
            }, queue: .main)
            tree.runAction(action)
            
            let sawSound = sounds["saw"]!
            ballNode.runAction(SCNAction.playAudio(sawSound, waitForCompletion: false))
        }
    }
}
