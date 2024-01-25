//
//  GameScene.swift
//  Teilchensimulation_iPhone
//
//  Created by Hans-Christian v. Bothmer on 09.01.24.
//

import SpriteKit
import GameplayKit

struct Vector {
    var x: CGFloat
    var y: CGFloat

    // Vektoraddition
    static func +(left: Vector, right: Vector) -> Vector {
        return Vector(x: left.x + right.x, y: left.y + right.y)
    }

    // Vektorsubtraktion
    static func -(left: Vector, right: Vector) -> Vector {
        return Vector(x: left.x - right.x, y: left.y - right.y)
    }

    // Skalarprodukt
    static func *(left: Vector, right: Vector) -> CGFloat {
        return left.x * right.x + left.y * right.y
    }

    // Skalarmultiplikation
    static func *(scalar: CGFloat, vector: Vector) -> Vector {
        return Vector(x: scalar * vector.x, y: scalar * vector.y)
    }

    // Norm (Länge) eines Vektors
    func norm() -> CGFloat {
        return sqrt(x*x + y*y)
    }

    // Einheitsvektor
    func normalized() -> Vector {
        let length = norm()
        return Vector(x: x/length, y: y/length)
    }
    
    // Vektor-Subtraktionszuweisung
    static func -=(left: inout Vector, right: Vector) {
        left = left - right
    }

    // Vektor-Additionszuweisung
    static func +=(left: inout Vector, right: Vector) {
        left = left + right
    }
    
    // Methode zum Drehen des Vektors um einen gegebenen Winkel
    func rotated(by angle: CGFloat) -> Vector {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return Vector(x: x * cosAngle - y * sinAngle, y: x * sinAngle + y * cosAngle)
    }
}

// Hilfsfunktion, um die Geschwindigkeit in eine Farbe umzurechnen
func getColorFromSpeed(speed: CGFloat, minSpeed: CGFloat, maxSpeed: CGFloat) -> SKColor {
    let clampedSpeed = min(max(speed, minSpeed), maxSpeed) // Entspricht np.clip
    let normalizedSpeed = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)
    let blue = (1 - normalizedSpeed)
    let red = normalizedSpeed
    return SKColor(red: red, green: 0, blue: blue, alpha: 1)
}

// Radius der Teilchen
let radius: CGFloat = 20

// Wechselwirkung zwischen den Teilchen
let epsilon: CGFloat = 0.5 // Tiefe des Potentialtopfs
let sigma: CGFloat = 2.1 * radius * 0.89 // Breite des Potentialtopfs
let cutOff: CGFloat = max(sigma,2*radius) // cut off for the LJ-force

// das Potential
func lennardJonesPotential(distance: CGFloat) -> CGFloat {
    // Überprüfen Sie, ob die Distanz kleiner als der Cutoff ist, und ersetzen Sie sie ggf.
    let effectiveDistance = distance < cutOff ? cutOff : distance
    let sigmaOverR = sigma / effectiveDistance

    let sigmaOverR6 = pow(sigmaOverR, 6)
    let sigmaOverR12 = sigmaOverR6 * sigmaOverR6

    return 4 * epsilon * (sigmaOverR12 - sigmaOverR6)
}

// die ableitung des potentials
func lennardJonesForce(distance: CGFloat) -> CGFloat {
    // avoid numerical instabillity for small distances
    // or closer than 2*radius
    if distance < cutOff  {
        return 0
    }
    let sigmaOverR = sigma / distance
    let sigmaOverR6 = pow(sigmaOverR, 6)
    let sigmaOverR12 = sigmaOverR6 * sigmaOverR6
    //return epsilon * (sigmaOverR12 - sigmaOverR6)
    //here: force = 0 at d=s
    return 24 * epsilon * (2 * sigmaOverR12 - sigmaOverR6) / distance
    // here: Force=0 at (s/d) = (1/2)^(1/6) = 0,89
    //                  d=s/0,89  or   s=0,89*d

}

class Particle {
    var position: Vector
    var velocity: Vector
    var radius: CGFloat // Radius des Partikels
    var mass: CGFloat = 1.0 // Standardmasse
    weak var node: SKShapeNode?

    // Initialisierung
    init(position: Vector, velocity: Vector, radius: CGFloat) {
        self.position = position
        self.velocity = velocity
        self.radius = radius
    }

    // Methode zum Austauschen der X- und Y-Koordinaten
    func swapCoordinates() {
        // Tauschen der Positionskoordinaten
        position = Vector(x: position.y, y: position.x)
        // Tauschen der Geschwindigkeitskoordinaten
        velocity = Vector(x: velocity.y, y: velocity.x)
    }

    func update() {
        // Aktualisiere die Position basierend auf der Geschwindigkeit
        position = position + velocity
    }

    // Füge eine Methode hinzu, um die Partikelgeschwindigkeit zu umzukehren, wenn sie die Wände berühren
    func checkBounds(maxX: CGFloat, maxY: CGFloat) {
        // Überprüfe die linke (bei x = 0 + Radius) und rechte (bei x = maxX - Radius) Wand
        if position.x - radius <= 0 {
            velocity.x = -velocity.x
            position.x = radius // Setze die Position auf den Radius, um Überlappung mit der Wand zu vermeiden
        } else if position.x + radius >= maxX {
            velocity.x = -velocity.x
            position.x = maxX - radius // Setze die Position auf maxX - Radius, um Überlappung zu vermeiden
        }

        // Überprüfe die untere (bei y = 0 + Radius) und obere (bei y = maxY - Radius) Wand
        if position.y - radius <= 0 {
            velocity.y = -velocity.y
            position.y = radius // Verhindere Überlappung mit der Wand
        } else if position.y + radius >= maxY {
            velocity.y = -velocity.y
            position.y = maxY - radius // Verhindere Überlappung
        }
    }

    func updateColor(minSpeed: CGFloat, maxSpeed: CGFloat) {
        let speedValue = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        let color = getColorFromSpeed(speed: speedValue, minSpeed: minSpeed, maxSpeed: maxSpeed)
        node?.fillColor = color
        node?.strokeColor = color // Aktualisiere auch die Randfarbe
    }
    
    func collide(with other: Particle) {
            let delta = position - other.position
            let distance = delta.norm()
            let radiusSum = self.radius + other.radius

            if distance < radiusSum {
                let normal = delta.normalized()
                let relativeVel = velocity - other.velocity
                let dotProduct = relativeVel * normal

                if dotProduct < 0 {
                    let impact = dotProduct * normal
                    velocity -= impact
                    other.velocity += impact
                }
            }
        }
    
    func interact(with other: Particle) {
        let delta = position - other.position // Differenz der Positionen
        let distance = delta.norm() // Distanz zwischen den Partikeln

        let forceMagnitude = lennardJonesForce(distance: distance)
        let forceDirection = delta.normalized() // Richtung der Kraft
        let force = forceMagnitude * forceDirection  // Vektor der Kraft

        self.velocity += (1/2) * force // Kraft auf dieses Partikel anwenden
        other.velocity -= (1/2) * force  // Gegenkraft auf anderes Partikel anwenden
    }
    
    func kineticEnergy() -> CGFloat {
        return 0.5 * mass * (velocity.x * velocity.x + velocity.y * velocity.y)
    }


}

class ParticleSimulation {
    var particles: [Particle] = []
    var lineNodes = [SKShapeNode]()

    // Exponentielle Glättungskonstante
    let alpha: CGFloat = 0.05

    // Geglättete Energiewerte
    var smoothedKineticEnergy: CGFloat = 0
    var smoothedPotentialEnergy: CGFloat = 0
    var smoothedEnergy: CGFloat = 0

    // Berechnet die gesamte kinetische Energie aller Partikel.
    func totalKineticEnergy() -> CGFloat {
        var totalEnergy: CGFloat = 0.0
        for particle in particles {
            // Addiert die kinetische Energie jedes Partikels zur Gesamtenergie.
            totalEnergy += particle.kineticEnergy()
        }
        return totalEnergy
    }

    // Berechnet die gesamte potentielle Energie basierend auf den Wechselwirkungen zwischen allen Partikelpaaren.
    func totalPotentialEnergy() -> CGFloat {
        var totalEnergy: CGFloat = 0.0
        // Durchläuft jedes Paar von Partikeln, um deren Beitrag zur potentiellen Energie zu berechnen.
        for i in 0..<particles.count {
            for j in i+1..<particles.count {
                let distance = (particles[i].position - particles[j].position).norm()
                // Addiert die Lennard-Jones-Potentialenergie basierend auf ihrem Abstand.
                totalEnergy += lennardJonesPotential(distance: distance)
            }
        }
        return totalEnergy
    }

    // Berechnet die Gesamtenergie (kinetisch + potentiell) des Systems.
    func totalEnergy() -> CGFloat {
        return totalKineticEnergy() + totalPotentialEnergy()
    }

    // Aktualisierung der geglätteten Energie
    func updateSmoothedEnergies() {
        let currentKineticEnergy = totalKineticEnergy()
        let currentPotentialEnergy = totalPotentialEnergy()
        
        // Exponentielle Glättung anwenden
        smoothedKineticEnergy = alpha * currentKineticEnergy + (1 - alpha) * smoothedKineticEnergy
        smoothedPotentialEnergy = alpha * currentPotentialEnergy + (1 - alpha) * smoothedPotentialEnergy
        smoothedEnergy = smoothedKineticEnergy+smoothedPotentialEnergy
    }
        
    init(numberOfParticles: Int, maxX: CGFloat, maxY: CGFloat) {
        for _ in 0..<numberOfParticles {
            let particle = createParticle(maxX: maxX, maxY: maxY)
            particles.append(particle)
        }
    }

    func createParticle(maxX: CGFloat, maxY: CGFloat) -> Particle {
        let position = Vector(x: CGFloat.random(in: 0...maxX), y: CGFloat.random(in: 0...maxY))
        let velocity = Vector(x: CGFloat.random(in: -3...3), y: CGFloat.random(in: -3...3))
        return Particle(position: position, velocity: velocity, radius: radius)
    }

    func update(maxX: CGFloat, maxY: CGFloat, scene: SKScene) {
        // Energien berechnen und glaetten
        updateSmoothedEnergies()

        // Entfernen Sie alle vorherigen Linien
        for line in lineNodes {
            line.removeFromParent()
        }
        lineNodes.removeAll()

        // Überprüfe jede Partikelkollision mit jeder anderen
        for i in 0..<particles.count {
            for j in i+1..<particles.count {
                particles[i].collide(with: particles[j])
                particles[i].interact(with: particles[j])
            }
        }

        // Aktualisiere die Positionen und überprüfe die Grenzen für jedes Partikel
        for particle in particles {
            particle.update()
            particle.checkBounds(maxX: maxX, maxY: maxY)
            particle.updateColor(minSpeed: 1, maxSpeed: 5) // Stelle sicher, dass die Geschwindigkeitswerte angemessen sind
        }
        
        // Zeichne Linien für nahe Partikel
        for i in 0..<particles.count {
            for j in i+1..<particles.count {
                let distance = (particles[i].position - particles[j].position).norm()
                if distance < 2*sigma {
                    let line = SKShapeNode()
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: particles[i].position.x, y: particles[i].position.y))
                    path.addLine(to: CGPoint(x: particles[j].position.x, y: particles[j].position.y))
                    line.path = path
                    line.strokeColor = SKColor.white
                    line.lineWidth = 1.0
                    line.zPosition = -2 // Setze die Linien unter die Partikel
                    scene.addChild(line)
                    lineNodes.append(line)
                }
            }
        }

    }
}

class GameScene: SKScene {
 //   private var containerNode = SKNode() // Der Container-Knoten
    var particleSimulation: ParticleSimulation!
//    var colderButtonBackground: SKLabelNode!
//    var warmerButtonBackground: SKLabelNode!
    var warmerButtonBackground: SKShapeNode!
    var colderButtonBackground: SKShapeNode!
    var minusButton: SKShapeNode!
    var plusButton: SKShapeNode!
    var kineticEnergyLabel: SKLabelNode!
    var potentialEnergyLabel: SKLabelNode!
    var totalEnergyLabel: SKLabelNode!
    var energyValueFormatter: NumberFormatter!
    
    var isInitialized = false


    
    // erzeuge in der Scene eine Kreis fuer ein Teilchen
    func createParticleNode(for particle: Particle) -> SKShapeNode {
        let particleNode = SKShapeNode(circleOfRadius: particle.radius)
        particleNode.position = CGPoint(x: particle.position.x, y: particle.position.y)
        particleNode.fillColor = SKColor.white
        particleNode.zPosition = -1 // Partikel über den Linien, unter den Buttons
        addChild(particleNode)
        //containerNode.addChild(particleNode)
        
        // debugging
        print("Partikelknoten hinzugefügt bei \(particleNode.position)")

        return particleNode
    }

    func positionUIElements() {
        // Positionierung der "wärmer" und "kälter" Buttons
        warmerButtonBackground.position = CGPoint(x: self.size.width / 2 + 60, y: 50)
        colderButtonBackground.position = CGPoint(x: self.size.width / 2 - 60, y: 50)

        // Positionierung der "+" und "-" Buttons
        minusButton.position = CGPoint(x: colderButtonBackground.position.x - 80, y: colderButtonBackground.position.y)
        plusButton.position = CGPoint(x: warmerButtonBackground.position.x + 80, y: warmerButtonBackground.position.y)

        // Positionierung der Energielabels
        kineticEnergyLabel.position = CGPoint(x: 10, y: self.size.height - 30)
        potentialEnergyLabel.position = CGPoint(x: self.size.width - 10, y: self.size.height - 50)
        totalEnergyLabel.position = CGPoint(x: self.size.width - 10, y: self.size.height - 70)
    }

    override func didMove(to view: SKView) {
        // debugging
        print("GameScene: didMove wurde aufgerufen")
        
        
        // Setze die Größe der Szene auf die Größe der Ansicht
        self.size = view.bounds.size

        // Hintergrund Schwarz
        backgroundColor = SKColor.black
        
        // Füge den Container-Knoten der Szene hinzu
        //addChild(containerNode)

        // Erstelle die Partikelsimulation mit den Dimensionen der Szene
        particleSimulation = ParticleSimulation(numberOfParticles: 30, maxX: self.size.width, maxY: self.size.height)

        for particle in particleSimulation.particles {
            let particleNode = createParticleNode(for: particle)
            particle.node = particleNode
        }

        // Erstelle den Hintergrund für den "wärmer" Button
        warmerButtonBackground = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        warmerButtonBackground.fillColor = SKColor.red
        // Setze den Rand des "wärmer" Button-Hintergrunds auf transparent
        warmerButtonBackground.strokeColor = SKColor.clear
        warmerButtonBackground.position = CGPoint(x: self.size.width / 2 + 60, y: 50)
        warmerButtonBackground.name = "warmerButton"
        addChild(warmerButtonBackground)

        // Erstelle die Beschriftung für den "wärmer" Button
        let warmerButtonLabel = SKLabelNode(fontNamed: "Helvetica")
        warmerButtonLabel.text = "Wärmer"
        warmerButtonLabel.fontSize = 20
        warmerButtonLabel.fontColor = SKColor.white
        warmerButtonLabel.position = CGPoint(x: 0, y: -10) // Zentriert auf dem Hintergrund
        warmerButtonBackground.addChild(warmerButtonLabel)

        // Erstelle den Hintergrund für den "kälter" Button
        colderButtonBackground = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        colderButtonBackground.fillColor = SKColor.blue
        // Setze den Rand des "kälter" Button-Hintergrunds auf transparent
        colderButtonBackground.strokeColor = SKColor.clear
        colderButtonBackground.position = CGPoint(x: self.size.width / 2 - 60, y: 50)
        colderButtonBackground.name = "colderButton"
        addChild(colderButtonBackground)

        // Erstelle die Beschriftung für den "kälter" Button
        let colderButtonLabel = SKLabelNode(fontNamed: "Helvetica")
        colderButtonLabel.text = "Kälter"
        colderButtonLabel.fontSize = 20
        colderButtonLabel.fontColor = SKColor.white
        colderButtonLabel.position = CGPoint(x: 0, y: -10) // Zentriert auf dem Hintergrund
        colderButtonBackground.addChild(colderButtonLabel)
        
        // Initialisiere den "minusButton"
        minusButton = SKShapeNode(circleOfRadius: 20)
        // Positioniere den minusButton links vom warmerButtonBackground
        minusButton.position = CGPoint(x: colderButtonBackground.position.x - 80, y: colderButtonBackground.position.y)
        minusButton.fillColor = SKColor.gray
        minusButton.name = "minusButton"
        addChild(minusButton)

        let minusLabel = SKLabelNode(text: "-")
        minusLabel.fontColor = SKColor.white
        minusLabel.position = CGPoint(x: 0, y: -10) // Zentriert auf dem Button
        minusButton.addChild(minusLabel)

        // Erstelle den "+" Button
        plusButton = SKShapeNode(circleOfRadius: 20)
        plusButton.fillColor = SKColor.gray
        plusButton.position = CGPoint(x: warmerButtonBackground.position.x + 80, y: warmerButtonBackground.position.y)
        plusButton.name = "plusButton"
        addChild(plusButton)

        let plusLabel = SKLabelNode(text: "+")
        plusLabel.fontColor = SKColor.white
        plusLabel.position = CGPoint(x: 0, y: -10) // Zentriert auf dem Button
        plusButton.addChild(plusLabel)
        
        // Initialisiert die Labels für die Anzeige der Energiewerte.
        kineticEnergyLabel = createEnergyLabel()
        kineticEnergyLabel.horizontalAlignmentMode = .left  // Setzen Sie die Ausrichtung auf links
        kineticEnergyLabel.position = CGPoint(x: 10, y: self.size.height - 40)
        addChild(kineticEnergyLabel)

        potentialEnergyLabel = createEnergyLabel()
        potentialEnergyLabel.horizontalAlignmentMode = .left
        potentialEnergyLabel.position = CGPoint(x: 10, y: self.size.height - 60)
        addChild(potentialEnergyLabel)

        totalEnergyLabel = createEnergyLabel()
        totalEnergyLabel.horizontalAlignmentMode = .left
        totalEnergyLabel.position = CGPoint(x: 10, y: self.size.height - 80)
        addChild(totalEnergyLabel)
        
        // Initialisiere den NumberFormatter
        energyValueFormatter = createEnergyValueFormatter()
        
        // flag setzen
        isInitialized = true

    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Positioniere UI-Elemente neu
        if isInitialized {
            positionUIElements()
        }
        
        // Überprüfen Sie, ob sich die Breite und Höhe vertauscht haben
        if oldSize.width == self.size.height && oldSize.height == self.size.width {
            for particle in particleSimulation.particles {
                particle.swapCoordinates()
            }
        }
    }

    func adjustSceneSize(newSize: CGSize) {
        self.size = newSize
        // Führen Sie hier weitere Anpassungen durch, falls nötig
    }

    
    // Erstellt und konfiguriert einen NumberFormatter für die Anzeige der Energiebeträge.
    private func createEnergyValueFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 2
        return formatter
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        particleSimulation.update(maxX: self.frame.maxX, maxY: self.frame.maxY, scene: self)

        // Wird jede Frame aufgerufen
        //print("GameScene: update")
        
        for particle in particleSimulation.particles {
            particle.node?.position = CGPoint(x: particle.position.x, y: particle.position.y)
        }
        
        // Setzt die Texte der Labels auf die aktuellen Energiewerte mit einer Nachkommastelle.
        kineticEnergyLabel.text = "Kinetic Energy: \(energyValueFormatter.string(from: NSNumber(value: particleSimulation.smoothedKineticEnergy)) ?? "")"
        potentialEnergyLabel.text = "Potential Energy: \(energyValueFormatter.string(from: NSNumber(value: particleSimulation.smoothedPotentialEnergy)) ?? "")"
        totalEnergyLabel.text = "Total Energy: \(energyValueFormatter.string(from: NSNumber(value: particleSimulation.smoothedEnergy)) ?? "")"
        
        // Debugging
        //print("MaxX: \(self.frame.maxX)")
        //print("Width: \(self.size.width)")
        //print("size: \(self.size)")


    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let touchedNodes = nodes(at: touchLocation)
        
        for node in touchedNodes {
            if node.name == "warmerButton" {
                // Erhöhe die Geschwindigkeit aller Partikel um 10%
                for particle in particleSimulation.particles {
                    particle.velocity = 1.1 * particle.velocity
                }
            } else if node.name == "colderButton" {
                // Verringere die Geschwindigkeit aller Partikel um 10%
                for particle in particleSimulation.particles {
                    particle.velocity = 0.9 * particle.velocity
                }
            } else if node.name == "minusButton" {
                // Der Minus-Button wurde berührt. Ziel ist es, ein Partikel zu entfernen.
                
                // Überprüfe, ob es Partikel in der Simulation gibt.
                if let lastParticle = particleSimulation.particles.last {
                    // Wenn ja, entferne das visuelle Partikel (SKShapeNode) aus der SKScene.
                    lastParticle.node?.removeFromParent() // Entferne das Partikel aus der Szene
                    
                    // Entferne das letzte Partikel auch aus der Liste der Partikel in der Simulation.
                    particleSimulation.particles.removeLast() // Entferne das Partikel aus der Simulation
                }
            } else if node.name == "plusButton" {
                // Der Plus-Button wurde berührt. Ziel ist es, ein neues Partikel hinzuzufügen.
                
                // Erzeuge ein neues Partikel mit einer zufälligen Position und Geschwindigkeit.
                let newParticle = particleSimulation.createParticle(maxX: self.size.width, maxY: self.size.height)
                
                // Füge das neue Partikel zur Liste der Partikel in der Simulation hinzu.
                particleSimulation.particles.append(newParticle)
                
                // Erzeuge ein visuelles Element (SKShapeNode) für das neue Partikel und füge es der Szene hinzu.
                // Speichere eine Referenz auf das visuelle Element im Partikel selbst, um es später aktualisieren zu können.
                newParticle.node = createParticleNode(for: newParticle)
            }
        }
    }
    
    
    // Hilfsfunktion zur Erstellung eines Energielabels.
    private func createEnergyLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica")
        label.fontSize = 14
        label.horizontalAlignmentMode = .right
        label.fontColor = SKColor.white
        return label
    }


}
