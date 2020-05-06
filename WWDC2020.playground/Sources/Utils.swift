import UIKit

public func readFasta(fileName: String) -> BitVector {
    let path = Bundle.main.path(forResource: fileName, ofType: "fasta")!
    let read = try! String(contentsOfFile: path)
    // cut out first line and join all the others
    let str = read.split(separator: "\n")[1...].joined()
    return stringToBitVector(s: str)
}

public func drawGenomeVisualization(rect: CGRect, editIdx: (sub: [Int], gapA: [Int], gapB: [Int]), length: Int) {
    // draw circles
    let outerPath = UIBezierPath()
    let innerPath = UIBezierPath()
    let blankPath = UIBezierPath()
    
    let center = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height / 2.0)
    let outerRadius = min(rect.width, rect.height) / 2.0 - 20.0
    let innerRadius = min(rect.width, rect.height) / 2.0 - 30.0
    let blankRadius = min(rect.width, rect.height) / 2.0 - 40.0
    let startAngle = CGFloat.pi * 7.0 / 12.0
    let endAngle = CGFloat.pi * 5.0 / 12.0
    let totalAngle = CGFloat.pi * 22.0 / 12.0
    
    outerPath.move(to: center)
    outerPath.addArc(withCenter: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    outerPath.close()
    
    innerPath.move(to: center)
    innerPath.addArc(withCenter: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    innerPath.close()
    
    // blank path to hide the center region with a circle
    blankPath.move(to: center)
    blankPath.addArc(withCenter: center, radius: blankRadius, startAngle: 0.0, endAngle: 2 * CGFloat.pi, clockwise: true)
    blankPath.close()
    
    colorBaseGenome.setFill()
    outerPath.fill()
    
    colorOtherGenome.setFill()
    innerPath.fill()
    
    colorBackground.setFill()
    blankPath.fill()
    
    // draw the lines representing gap edits in A
    let aGapPath = UIBezierPath()
    
    for idx in editIdx.gapA {
        let p1 = CGPoint(x: innerRadius, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
        let p2 = CGPoint(x: outerRadius, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
        
        aGapPath.move(to: CGPoint(x: center.x + p1.x, y: center.y + p1.y))
        aGapPath.addLine(to: CGPoint(x: center.x + p2.x, y: center.y + p2.y))
    }
    
    aGapPath.close()
    aGapPath.lineWidth = 1.0
    colorBackground.setStroke()
    aGapPath.stroke()
    
    // draw the lines representing gap edits in B
    let bGapPath = UIBezierPath()
    
    for idx in editIdx.gapB {
        let p1 = CGPoint(x: blankRadius, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
        let p2 = CGPoint(x: innerRadius, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
        
        bGapPath.move(to: CGPoint(x: center.x + p1.x, y: center.y + p1.y))
        bGapPath.addLine(to: CGPoint(x: center.x + p2.x, y: center.y + p2.y))
    }
    
    bGapPath.close()
    bGapPath.lineWidth = 1.0
    colorBackground.setStroke()
    bGapPath.stroke()
    
    // draw the lines representing substitution edits
    if showMismatches {
        let subPath = UIBezierPath()
        
        for idx in editIdx.sub {
            let p1 = CGPoint(x: outerRadius + 5, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
            let p2 = CGPoint(x: outerRadius + 15, y: 0).applying(CGAffineTransform(rotationAngle: startAngle + CGFloat(idx) / CGFloat(length) * totalAngle))
            
            subPath.move(to: CGPoint(x: center.x + p1.x, y: center.y + p1.y))
            subPath.addLine(to: CGPoint(x: center.x + p2.x, y: center.y + p2.y))
        }
        
        subPath.close()
        subPath.lineWidth = 0.3
        colorMismatch.setStroke()
        subPath.stroke()
    }
}
