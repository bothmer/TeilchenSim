//
//  GameViewController.swift
//  Teilchensimulation_iPhone
//
//  Created by Hans-Christian v. Bothmer on 09.01.24.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // debugging
        print("viewDidLoad wurde aufgerufen")
        
        if let view = self.view as! SKView? {
            
            // debugging
            print("SKView gefunden")
            
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            // Aktivieren Sie diese Optionen, um Debugging-Informationen in der SKView anzuzeigen
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
        } else {
            print("Keine SKView gefunden")
        }
    }


    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // debugging
        print("viewWillTransition: Neue Größe: \(size)")

        
        // Ausgabe der alten Größe der Ansicht
        let oldSize = self.view.frame.size
        print("Alte Größe: \(oldSize)")
        
        // Aktuelle maxX und maxY ausgeben
        let currentMaxX = self.view.frame.maxX
        let currentMaxY = self.view.frame.maxY
        print("Aktuelle maxX: \(currentMaxX), maxY: \(currentMaxY)")

        // Hier überprüfen Sie die Größe der SKScene, die von der SKView dargestellt wird
        if let skView = self.view as? SKView, let scene = skView.scene {
            print("Aktuelle Größe der SKScene vor der Transition: \(scene.size)")
        }


        // Ausgabe der neuen Größe, zu der gewechselt wird
        print("Neue Größe: \(size)")

        coordinator.animate(alongsideTransition: { (context) in
            // Animationen oder Anpassungen, die während der Größenänderung durchgeführt werden
        }) { (context) in
            // Code, der nach Abschluss der Größenänderung ausgeführt wird
            let newMaxX = self.view.frame.maxX
            let newMaxY = self.view.frame.maxY
            print("Neue maxX: \(newMaxX), maxY: \(newMaxY)")
            
            // Nachdem die Transition abgeschlossen ist
            if let skView = self.view as? SKView, let scene = skView.scene {
                print("Neue Größe der SKScene nach der Transition: \(scene.size)")
            }


            print("Größenänderung von \(oldSize) zu \(size) abgeschlossen.")
        }

        if let skView = self.view as? SKView, let scene = skView.scene as? GameScene {
            coordinator.animate(alongsideTransition: { _ in
                // Hier können Sie die Position Ihrer Buttons anpassen
            }) { _ in
                scene.adjustSceneSize(newSize: size)
            }
        }
     }

    
}
