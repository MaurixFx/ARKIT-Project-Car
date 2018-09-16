//
//  ViewController.swift
//  projectCar
//
//  Created by Mauricio Figueroa olivares on 10-09-18.
//  Copyright © 2018 Mauricio Figueroa olivares. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        registerGestureRecognizers()
        self.setUpAccelerometer()
    }
    
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(recognizer :UIGestureRecognizer) {
        let carScene = SCNScene(named: "art.scnassets/simplecar.dae")!
        guard let car = carScene.rootNode.childNode(withName: "car", recursively: false) else { return }
        let fromLeftWheel = car.childNode(withName: "wheelLeftFront", recursively: false)!
        let fromRightWheel = car.childNode(withName: "wheelRightFront", recursively: false)!
        let rearLefttWheel = car.childNode(withName: "wheelLeftBack", recursively: false)!
        let rearRightWheel = car.childNode(withName: "wheelRightBack", recursively: false)!
        
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: fromLeftWheel)
        let v_frontRighttWheel = SCNPhysicsVehicleWheel(node: fromRightWheel)
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLefttWheel)
        let v_reartRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel)
        
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        car.position = currentPositionOfCamera
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: car, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        car.physicsBody = body
        self.vehicle = SCNPhysicsVehicle(chassisBody: car.physicsBody!, wheels: [v_reartRightWheel, v_rearLeftWheel, v_frontRighttWheel, v_frontLeftWheel])
        self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        self.sceneView.scene.rootNode.addChildNode(car)
    }
    
    func setUpAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.accelerometerDidChange(acceleration: accelerometerData!.acceleration)
            })
            
        } else {
            print("accelerometer not available")
        }
    }
    
    func accelerometerDidChange(acceleration: CMAcceleration) {
        print(acceleration.x)
        print(acceleration.y)
    }
    
    func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let floorNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(CGFloat(planeAnchor.extent.z))))
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "concrete.png")
        floorNode.geometry?.firstMaterial?.isDoubleSided = true
        floorNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        floorNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        let staticBody = SCNPhysicsBody.static()
        floorNode.physicsBody = staticBody
        return floorNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let floorNode = createFloor(planeAnchor: planeAnchor)
        node.addChildNode(floorNode)
        print("new flat surface detected, new ARPlaneAnchor added")
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("updating floor's anchor...")
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
            
        }
        let floorNode = createFloor(planeAnchor: planeAnchor)
        node.addChildNode(floorNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
