import UIKit

var showMismatches = false
let baseFile = "illinois_MN988713_1"
let baseName = "Illinois SARS-CoV-2"
let otherFiles = ["wuhan_seafood_MN908947_3", "human_sars_NC_004718_3", "bat_sars_MG772934_1", "seattle_229E_KY983587_1", "camel_mers_KP719932_1", "human_mers_MN120514_1"]
let otherNames = ["Wuhan SARS-CoV-2", "Human SARS-CoV", "Bat SARS-CoV", "Human CoV 229E", "Camel MERS-CoV", "Human MERS-CoV"]
let strQoS: [DispatchQoS.QoSClass] = [.userInteractive, .userInteractive, .userInteractive, .utility, .utility, .utility]

// FASTA variables
let baseStr = readFasta(fileName: baseFile)
var minLength = baseStr.length
var otherStr: [BitVector] = []

// edit distance variables
var levenshteinDist: [Int] = []
var levenshteinStr: [(a: String, b: String, mismatches: String)] = []
var levenshteinIdx: [(sub: [Int], gapA: [Int], gapB: [Int])] = []
var levenshteinLength: [Int] = []

// UI variables
var currStrIdx = 0 // describes the global state (which virus genome)

let messages = ["The 2019 coronavirus outbreak is a global pandemic.", "The 2019 coronavirus outbreak is a global pandemic.\n\nWith millions of cases, it is more deadly and more contagious than the annual flu.", "In this project, we will explore how its RNA genome compares to previous coronaviruses.", "In this project, we will explore how its RNA genome compares to previous coronaviruses.\n\nThis isn't an easy task.", "Computing the \"Levenshtein\" distance between coronavirus genomes of ~30,000 nucleotides long takes ~900 million operations, and an enormous amount of memory.", "Computing the \"Levenshtein\" distance between coronavirus genomes of ~30,000 nucleotides long takes ~900 million operations, and an enormous amount of memory.\n\nBut with clever algorithmic tricks, it can be done.", "Computing the \"Levenshtein\" distance between coronavirus genomes of ~30,000 nucleotides long takes ~900 million operations, and an enormous amount of memory.\n\nBut with clever algorithmic tricks, it can be done.\n\nEnjoy."]

public let viewWidth = 600
public let viewHeight = 800

// UI elements that need to be accessed globally
var genomeButtons: [UIButton] = []
let percentText = UILabel()
let aText = UILabel()
let bText = UILabel()
let markedText = UILabel()
let insideLabel = UILabel()
let microScroll = UIScrollView()
let otherMicroLabel = UILabel()
let genomeVisualization = GenomeVisualization()

// UI colors
let colorScrollMatch = UIColor.white
let colorScrollBack = UIColor.black
let colorMismatch = UIColor.white
let colorButtonDisable = UIColor.gray
let colorButtonEnable = UIColor.white
let colorBaseGenome = UIColor(red: 97.0 / 255.0, green: 226.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0) // blue
let colorOtherGenome = UIColor(red: 251.0 / 255.0, green: 31.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0) // red
//let colorText = UIColor(red: 243.0 / 255.0, green: 169.0 / 255.0, blue: 192.0 / 255.0, alpha: 1.0) // pink
let colorText = UIColor.white
let colorBackground = UIColor.black

public func initVars(shouldShowMismatches: Bool) {
    showMismatches = shouldShowMismatches
    
    // read other files
    for f in otherFiles {
        let s = readFasta(fileName: f)
        minLength = min(minLength, s.length)
        otherStr.append(s)
    }

    baseStr.length = minLength

    for s in otherStr {
        s.length = minLength
    }
    
    // initialize edit distance variables
    // everything is calculated once and cached
    levenshteinDist = [Int](repeating: 0, count: otherStr.count)
    levenshteinStr = [(a: String, b: String, mismatches: String)](repeating: (a: "", b: "", mismatches: ""), count: otherStr.count)
    levenshteinIdx = [(sub: [Int], gapA: [Int], gapB: [Int])](repeating: (sub: [], gapA: [], gapB: []), count: otherStr.count)
    levenshteinLength = [Int](repeating: 0, count: otherStr.count)
    
    // calculate edit distance for first genome
    let hammingDistFirst = hamming(A: baseStr, B: otherStr[0])
    let resFirst = levenshtein(A: baseStr, B: otherStr[0], k: hammingDistFirst)
    levenshteinDist[0] = resFirst.dist
    levenshteinStr[0] = editsToShortString(A: baseStr, B: otherStr[0], edits: resFirst.edits, maxLength: 1)
    levenshteinIdx[0] = editsToIdx(edits: resFirst.edits)
    levenshteinLength[0] = resFirst.edits.length
}

public func calcOtherDistances(controller: UIViewController) {
    // idea: always calculate edit distance for first genome first, so something can be drawn
    // then, use multiple threads to calculate edit distance for other genomes, and enabling the genome buttons when they are done
    // use main thread to update display as needed
    for (idx, s) in otherStr.enumerated() {
        if idx == 0 {
            continue
        }
        
        DispatchQueue.global(qos: strQoS[idx]).async {
            let hammingDist = hamming(A: baseStr, B: s)
            let res = levenshtein(A: baseStr, B: s, k: hammingDist)
            levenshteinDist[idx] = res.dist
            levenshteinStr[idx] = editsToShortString(A: baseStr, B: s, edits: res.edits, maxLength: 1)
            levenshteinIdx[idx] = editsToIdx(edits: res.edits)
            levenshteinLength[idx] = res.edits.length
            
            DispatchQueue.main.async {
                genomeButtons[idx].isEnabled = true
                genomeButtons[idx].setNeedsDisplay()
                controller.view.setNeedsDisplay()
            }
        }
    }
}

// visualize two genomes as two circles
class GenomeVisualization: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = colorBackground
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        drawGenomeVisualization(rect: rect, editIdx: levenshteinIdx[currStrIdx], length: levenshteinLength[currStrIdx])
    }
}

public class WWDCViewController: UIViewController {
    public override func loadView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
        view.backgroundColor = colorBackground
        
        let width: Int = viewWidth / (otherNames.count / 2)
        
        // buttons to select the virus genome at the top
        for (idx, name) in otherNames.enumerated() {
            let button = UIButton()
            
            button.frame = CGRect(x: (idx / 2) * width, y: 10 + (idx % 2) * 30, width: width, height: 30)
            button.setTitle(name, for: .normal)
            button.setTitleColor(colorButtonEnable, for: .normal)
            button.setTitleColor(colorButtonDisable, for: .disabled)
            button.tintColor = colorBackground
            button.titleLabel!.font = .systemFont(ofSize: 15)
            button.addTarget(self, action: #selector(self.genomeSelected), for: .touchUpInside)
            button.isEnabled = false
            
            genomeButtons.append(button)
            view.addSubview(button)
        }
        
        // display percentage match
        percentText.textColor = colorText
        percentText.frame = CGRect(x: 0, y: 80, width: viewWidth, height: 100)
        percentText.font = .systemFont(ofSize: 70)
        percentText.textAlignment = .center
        view.addSubview(percentText)
        
        let matchLabel = UILabel()
        matchLabel.text = "match"
        matchLabel.textColor = colorText
        matchLabel.frame = CGRect(x: 0, y: 150, width: viewWidth, height: 50)
        matchLabel.font = .systemFont(ofSize: 30)
        matchLabel.textAlignment = .center
        view.addSubview(matchLabel)
        
        // visualize virus genomes with partial circles
        genomeVisualization.frame = CGRect(x: 0, y: 200, width: viewWidth, height: 410)
        view.addSubview(genomeVisualization)
        
        // mark mismatches
        if showMismatches {
            let mismatchLabel = UILabel()
            mismatchLabel.text = "Mismatches"
            mismatchLabel.textColor = colorMismatch
            mismatchLabel.frame = CGRect(x: 60, y: Int(genomeVisualization.frame.origin.y + 40), width: 200, height: 20)
            mismatchLabel.font = .systemFont(ofSize: 15)
            mismatchLabel.textAlignment = .left
            view.addSubview(mismatchLabel)
        }
        
        // labels in the center of the genome visualization
        let outsideLabel = UILabel()
        outsideLabel.text = baseName
        outsideLabel.textColor = colorBaseGenome
        outsideLabel.frame = CGRect(x: 0, y: Int(genomeVisualization.frame.origin.y + genomeVisualization.frame.height / 2) - 40, width: viewWidth, height: 30)
        outsideLabel.font = .systemFont(ofSize: 20)
        outsideLabel.textAlignment = .center
        view.addSubview(outsideLabel)
        
        let versusLabel = UILabel()
        versusLabel.text = "vs"
        versusLabel.textColor = colorText
        versusLabel.frame = CGRect(x: 0, y: Int(genomeVisualization.frame.origin.y + genomeVisualization.frame.height / 2) - 7, width: viewWidth, height: 14)
        versusLabel.font = .systemFont(ofSize: 14)
        versusLabel.textAlignment = .center
        view.addSubview(versusLabel)
        
        insideLabel.textColor = colorOtherGenome
        insideLabel.frame = CGRect(x: 0, y: Int(genomeVisualization.frame.origin.y + genomeVisualization.frame.height / 2) + 10, width: viewWidth, height: 30)
        insideLabel.font = .systemFont(ofSize: 20)
        insideLabel.textAlignment = .center
        view.addSubview(insideLabel)
        
        // text on the bottom, displaying the short edit strings
        aText.textColor = colorBaseGenome
        aText.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        
        // marks the matching areas in the edit strings
        markedText.textColor = colorScrollMatch
        markedText.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        
        bText.textColor = colorOtherGenome
        bText.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        
        microScroll.frame = CGRect(x: 20, y: 40, width: viewWidth - 40, height: 70)
        microScroll.backgroundColor = colorScrollBack
        microScroll.addSubview(aText)
        microScroll.addSubview(markedText)
        microScroll.addSubview(bText)
        
        let microContainer = UIView(frame: CGRect(x: 0, y: 630, width: viewWidth, height: 150))
        microContainer.backgroundColor = colorScrollBack
        
        let baseMicroLabel = UILabel()
        baseMicroLabel.text = baseName
        baseMicroLabel.frame = CGRect(x: 20, y: 15, width: 200, height: 20)
        baseMicroLabel.textColor = colorBaseGenome
        baseMicroLabel.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        
        otherMicroLabel.frame = CGRect(x: 20, y: 115, width: 200, height: 20)
        otherMicroLabel.textColor = colorOtherGenome
        otherMicroLabel.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        
        microContainer.addSubview(baseMicroLabel)
        microContainer.addSubview(microScroll)
        microContainer.addSubview(otherMicroLabel)
        
        // manually run the selection once to initialize
        genomeSelected(sender: genomeButtons[0])
        
        view.addSubview(microContainer)
        
        // display the initial messages that stall for time (in reverse)
        // each message is removed when the next button is clicked
        for m in messages.reversed() {
            let messageView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
            messageView.backgroundColor = colorBackground
            
            let messageLabel = UILabel()
            messageLabel.text = m
            messageLabel.textColor = colorText
            messageLabel.frame = CGRect(x: viewWidth / 2 - 200, y: viewHeight / 2 - 200, width: 400, height: 300)
            messageLabel.numberOfLines = 0
            messageLabel.font = .systemFont(ofSize: 20)
            messageLabel.textAlignment = .left
            messageLabel.sizeToFit()
            messageView.addSubview(messageLabel)
            
            let nextButton = UIButton()
            nextButton.frame = CGRect(x: viewWidth / 2 + 100, y: viewHeight / 2 + 100, width: 100, height: 30)
            nextButton.setTitle("Next", for: .normal)
            nextButton.setTitleColor(colorButtonEnable, for: .normal)
            nextButton.tintColor = colorBackground
            nextButton.titleLabel!.font = .systemFont(ofSize: 20)
            nextButton.addTarget(self, action: #selector(self.nextView), for: .touchUpInside)
            messageView.addSubview(nextButton)
            
            view.addSubview(messageView)
        }
        
        self.view = view
    }
    
    @objc func nextView(sender: UIButton!) {
        UIView.animate(withDuration: 0.5, animations: {
            sender.superview!.alpha = 0.0
        }, completion: {_ in
            sender.superview!.removeFromSuperview()
        })
    }
    
    // update the view (buttons, visualization, text, etc.) when a genome button is clicked
    @objc func genomeSelected(sender: UIButton!) {
        genomeButtons[currStrIdx].isEnabled = true
        genomeButtons[currStrIdx].setTitleColor(colorButtonEnable, for: .disabled)
        currStrIdx = otherNames.firstIndex(of: sender.title(for: .normal)!)!
        genomeButtons[currStrIdx].isEnabled = false
        genomeButtons[currStrIdx].setTitleColor(colorOtherGenome, for: .disabled)
        
        let percentDiff = 100.0 * (1.0 - Double(levenshteinDist[currStrIdx]) / Double(minLength))
        percentText.text = String(format: "%.2f%%", percentDiff)
        
        // save old locations and make them invisible for the animation
        percentText.alpha = 0.0
        let oldPercentTextY = percentText.frame.origin.y
        percentText.frame.origin.y -= 10
        
        genomeVisualization.alpha = 0.0
        let oldGenomeVisY = genomeVisualization.frame.origin.y
        genomeVisualization.frame.origin.y += 10
        
        insideLabel.alpha = 0.0
        let oldInsideLabelY = insideLabel.frame.origin.y
        insideLabel.frame.origin.y += 10
        
        UIView.animate(withDuration: 0.5, animations: {
            percentText.alpha = 1.0
            percentText.frame.origin.y = oldPercentTextY
            
            genomeVisualization.alpha = 1.0
            genomeVisualization.frame.origin.y = oldGenomeVisY
            
            insideLabel.alpha = 1.0
            insideLabel.frame.origin.y = oldInsideLabelY
        })
        
        aText.text = levenshteinStr[currStrIdx].a
        aText.frame = CGRect(x: 0, y: 10, width: min(5000, levenshteinStr[currStrIdx].a.count * 10), height: 17)
        markedText.text = levenshteinStr[currStrIdx].mismatches
        markedText.frame = CGRect(x: 0, y: 27, width: min(5000, levenshteinStr[currStrIdx].mismatches.count * 10), height: 17)
        bText.text = levenshteinStr[currStrIdx].b
        bText.frame = CGRect(x: 0, y: 44, width: min(5000, levenshteinStr[currStrIdx].b.count * 10), height: 17)
        
        otherMicroLabel.text = otherNames[currStrIdx]
        insideLabel.text = otherNames[currStrIdx]
        
        microScroll.contentSize = CGSize(width: max(aText.bounds.width, bText.bounds.width), height: 50)
        microScroll.contentOffset = CGPoint(x: 0, y: 0)
        
        genomeVisualization.setNeedsDisplay()
        aText.setNeedsDisplay()
        markedText.setNeedsDisplay()
        bText.setNeedsDisplay()
    }
}
