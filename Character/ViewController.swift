//
//  ViewController.swift
//  Character
//
//  Created by Sai Kambampati on 6/8/21.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var entity: Entity?
    var anchor: AnchorEntity?
    private var modelCancellables = Set<AnyCancellable>()
    private var xMoveValue: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.sceneReconstruction = .mesh
        arView.session.run(config, options: [.removeExistingAnchors, .resetSceneReconstruction])
        arView.environment.sceneUnderstanding.options.insert([.collision, .physics, .receivesLighting, .occlusion])
        
        setupPhysicsOrigin()
        
        // Control Collisions
        let modelGroup = CollisionGroup(rawValue: 1 << 1)
        let modelMask = CollisionGroup.all.subtracting(modelGroup)
        
        let groguUSDZ = Bundle.main.url(forResource: "Grogu", withExtension: "usdz")!
        entity = try? ModelEntity.loadModel(contentsOf: groguUSDZ, withName: nil)
        entity?.scale = .init(repeating: 1.0)
        
        var characterControllerComp = CharacterControllerComponent(radius: 0.15, height: 0.15)
        characterControllerComp.collisionFilter = CollisionFilter(group: modelGroup, mask: modelMask)
        entity!.components[CharacterControllerComponent.self] = characterControllerComp

        anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: .zero))
        anchor!.addChild(entity!)
            
        arView.scene.addAnchor(anchor!)
        
        arView.installGestures(.all, for: entity! as! HasCollision)
        
        arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            let deltaTime = Float(event.deltaTime)
            self.entity?.moveCharacter(
                by: [self.xMoveValue, 0, 0],
                deltaTime: deltaTime,
                relativeTo: nil
            )
        }
        .store(in: &modelCancellables)
    }
    
    func setupPhysicsOrigin() {
        let physicsOrigin = Entity()
        physicsOrigin.scale = .init(repeating: 0.1)
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(physicsOrigin)
        arView.scene.addAnchor(anchor)
        arView.physicsOrigin = physicsOrigin
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first?.location(in: self.view)
        if touchLocation?.x ?? 0 > view.frame.width / 2 {
            xMoveValue = 0.001
        } else {
            xMoveValue = -0.001
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        xMoveValue = 0.0
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        xMoveValue = 0.0
    }
}
