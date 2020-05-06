import Foundation

let intToChar: [Character] = ["A", "C", "G", "T", "U", "R", "Y", "K", "M", "S", "W", "B", "D", "H", "V", "N"]
let charToInt: [Character: UInt] = ["A": 0, "C": 1, "G": 2, "T": 3, "U": 4, "R": 5, "Y": 6, "K": 7, "M": 8, "S": 9, "W": 10, "B": 11, "D": 12, "H": 13, "V": 14, "N": 15]

// 0 = match, 1 = mismatch, 2 = A gap, 3 = B gap

// A and B should be the same length
public func hamming(A: BitVector, B: BitVector) -> Int {
    precondition(A.length == B.length)

    var dist = 0

    for i in 0..<A.length {
        if A.get(idx: i) != B.get(idx: i) { // mismatch/substitution
            dist += 1
        }
    }

    return dist
}

func levenshteinBounded(A: BitVector, B: BitVector, k: Int) -> (dist: Int, edits: BitVector) {
    precondition(A.length == B.length) // assume both strings are the same length
    
    let n = A.length + 1
    // track current position as a sliding window, without worrying about out of bound indexes
    // sliding window length is 1 or 2 larger than k
    var lo = k % 2 == 0 ? (-k / 2) : (-k / 2 - 1) // inclusive
    var hi = lo + (k % 2 == 0 ? (k + 1) : (k + 2)) // exclusive
    
    // only save last two rows of the dp array, reusing these two for less memory cost
    var dp1 = [Int](repeating: 0, count: hi - lo)
    var dp2 = [Int](repeating: 0, count: hi - lo)
    var trace = [BitVector](repeating: BitVector(length: 0, factor: 0), count: n)
    // index of the left bounds of the sliding window
    var offsetLo = [Int](repeating: 0, count: n)
    var dist = Int.max
    
    // important property: each diagonal (parallel to main diagonal) is nondecreasing
    
    for i in 0..<n {
        if lo > i || hi &- 1 < i {
            // crossing the main diagonal means that we cannot reach the end with only k edits
            return (dist, BitVector(length: 0, factor: 0))
        }
    
        // ensure no index out of bound problems
        // two bounds: [lo, hi) is the theoretical bound of the sliding window
        // [l, h) is the actually used bound because they do not have indexing problems
        let l = max(lo, 0)
        let h = min(hi, n)
        
        trace[i] = BitVector(length: h &- l, factor: 2)
        offsetLo[i] = l
        
        var startIdx = 0
        
        if l == 0 { // B is length 0, so all gaps for B
            dp2[0] = i
            trace[i].set(idx: 0, val: 3 as UInt)
            startIdx = 1
        }
        
        for j in startIdx..<(h &- l) {
            if i == 0 { // A is length 0, so all gaps for A
                dp2[j] = j
                trace[i].set(idx: j, val: 2 as UInt)
            }else{
                let idx = j &+ l
                let prevIdx = idx &- offsetLo[i &- 1] // what index is the cell directly above dp[i][j]?
                
                if A.get(idx: i &- 1) == B.get(idx: idx &- 1) { // match
                    // usually dp[i][j] = dp[i - 1][j - 1]
                    dp2[j] = dp1[prevIdx &- 1]
                    trace[i].set(idx: j, val: 0 as UInt)
                }else{
                    // mismatch/substitution
                    // usually dp[i][j] = dp[i - 1][j - 1] + 1
                    var min = dp1[prevIdx &- 1] &+ 1
                    var edit = 1 as UInt
                    
                    // insert into A, gap in B
                    if idx < h &- 1 { // only if not right window boundary
                        // usually dp[i][j] = dp[i - 1][j] + 1
                        let a = dp1[prevIdx] &+ 1
                        
                        if a < min {
                            min = a
                            edit = 3 as UInt
                        }
                    }
                    
                    // insert into B, gap in A
                    if idx > l { // only if not left window boundary
                        // usually dp[i][j] = dp[i][j - 1] + 1
                        let a = dp2[j &- 1] &+ 1
                        
                        if a < min {
                            min = a
                            edit = 2 as UInt
                        }
                    }
                    
                    dp2[j] = min
                    trace[i].set(idx: j, val: edit)
                }
            }
            
            if j > 0 { // update previous row of dp with current row as soon as possible
                dp1[j &- 1] = dp2[j &- 1]
            }
        }
        
        dp1[h &- 1 &- l] = dp2[h &- 1 &- l]
        
        // now, shrink the left and right window bounds based on calculated edits
        
        if lo >= 0 {
            while lo <= h &- 1 && dp2[lo &- l] + abs(i &- lo) > k{
                lo = lo &+ 1
            }
        }
        
        if hi <= n {
            while hi &- 1 >= l && dp2[hi &- 1 &- l] + abs(hi &- 1 &- i) > k{
                hi = hi &- 1
            }
        }
        
        // move window forwards
        lo = lo &+ 1
        hi = hi &+ 1
        
        if i == n &- 1 { // got the result!
            dist = dp2[h &- 1 &- l]
        }
    }
    
    if dist > k {
        return (dist, BitVector(length: 0, factor: 0))
    }else{
        return (dist, backtrace(n: n, trace: trace, offsetLo: offsetLo))
    }
}

func backtrace(n: Int, trace: [BitVector], offsetLo: [Int]) -> BitVector {
    let edits = BitVector(length: 2 * n, factor: 2)
    var i = n - 1
    var j = n - 1
    var editIdx = 0
    
    while i > 0 || j > 0 {
        let idx = j - offsetLo[i]
        let edit = trace[i].get(idx: idx)
        
        edits.set(idx: editIdx, val: edit)
        
        if edit == 0 as UInt { // match
            i -= 1
            j -= 1
        }else if edit == 1 as UInt { // mismatch
            i -= 1
            j -= 1
        }else if edit == 2 as UInt { // A gap
            j -= 1
        }else if edit == 3 as UInt { // B gap
            i -= 1
        }
        
        editIdx += 1
    }
    
    edits.length = editIdx
    edits.reverseGet = true
    
    return edits
}

public func levenshtein(A: BitVector, B: BitVector, k: Int) -> (dist: Int, edits: BitVector){
    var currK = 1
    
    // exponential search
    while true {
        let res = levenshteinBounded(A: A, B: B, k: currK)
        
        if res.dist > currK {
            currK *= 2
            currK = min(currK, k)
        }else{
            return res
        }
    }
}

public class BitVector {
    var words: [UInt]
    public var length: Int
    var factor: Int
    var mask: UInt
    var reverseGet = false // works like a stack
    
    init(length: Int, factor: Int) {
        self.length = length
        self.factor = factor
        self.words = [UInt](repeating: 0 as UInt, count: (length * factor) / Int.bitWidth + ((length * factor) % Int.bitWidth == 0 ? 0 : 1))
        self.mask = (1 << self.factor) - 1 as UInt
    }
    
    func get(idx: Int) -> UInt {
        if self.reverseGet {
            let word = self.words[((self.length &- 1 &- idx) &* self.factor) >> Int.bitWidth.trailingZeroBitCount]
            let i = ((self.length &- 1 &- idx) &* self.factor) & (Int.bitWidth &- 1)
            return (word >> i) & self.mask
        }else{
            let word = self.words[(idx &* self.factor) >> Int.bitWidth.trailingZeroBitCount]
            let i = (idx &* self.factor) & (Int.bitWidth &- 1)
            return (word >> i) & self.mask
        }
    }
    
    func set(idx: Int, val: UInt) {
        let i = (idx &* self.factor) >> Int.bitWidth.trailingZeroBitCount
        let j = (idx &* self.factor) & (Int.bitWidth &- 1)
        self.words[i] = (self.words[i] & (~(self.mask << j))) | (val << j)
    }
}

public func bitVectorToString(b: BitVector) -> String {
    var res: [Character] = []
    
    for i in 0..<b.length {
        res.append(intToChar[Int(bitPattern: b.get(idx: i))])
    }
    
    return String(res)
}

public func stringToBitVector(s: String) -> BitVector {
    let res: BitVector = BitVector(length: s.count, factor: 4)
    var i: Int = 0
    
    for c in s {
        res.set(idx: i, val: charToInt[c]!)
        i += 1
    }
    
    return res
}

public func editsToString(A: BitVector, B: BitVector, edits: BitVector) -> (a: String, b: String) {
    var aChars: [Character] = []
    var bChars: [Character] = []
    var aIdx = 0
    var bIdx = 0
    
    for i in 0..<edits.length {
        let e = edits.get(idx: i)
        
        if e == 0 as UInt { // match
            aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx))])
            bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx))])
            aIdx += 1
            bIdx += 1
        }else if e == 1 as UInt { // mismatch
            aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx))])
            bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx))])
            aIdx += 1
            bIdx += 1
        }else if e == 2 as UInt { // A gap
            aChars.append(" ")
            bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx))])
            bIdx += 1
        }else if e == 3 as UInt { // B gap
            aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx))])
            bChars.append(" ")
            aIdx += 1
        }
    }
    
    return (String(aChars), String(bChars))
}

// algorithm to display regions near edits
// kind of like grep or diff
public func editsToShortString(A: BitVector, B: BitVector, edits: BitVector, maxLength: Int) -> (a: String, b: String, mismatches: String) {
    var aChars: [Character] = []
    var bChars: [Character] = []
    var mismatches: [Character] = []
    var aIdx = 0
    var bIdx = 0
    var matchLength = 0
    var start = true
    
    for i in 0..<edits.length {
        let e = edits.get(idx: i)
        
        if e == 0 as UInt { // match
            matchLength += 1
            aIdx += 1
            bIdx += 1
        }else{
            if (start && matchLength > maxLength + 1) || (matchLength > maxLength * 2 + 1) { // ellipsis will always take up 1 character (ellipsis = a single space, if between edits)
                if start {
                    aChars.append("…")
                    bChars.append("…")
                    mismatches.append(" ")
                }else{
                    for j in 0..<maxLength { // before ellipsis
                        aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx - (matchLength - j)))])
                        bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx - (matchLength - j)))])
                        mismatches.append("|")
                    }
                    
                    aChars.append(" ")
                    bChars.append(" ")
                    mismatches.append(" ")
                }
                
                for j in 0..<maxLength { // after ellipsis
                    aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx - (maxLength - j)))])
                    bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx - (maxLength - j)))])
                    mismatches.append("|")
                }
            }else{
                for j in 0..<matchLength { // no ellipsis, so use all characters
                    aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx - (matchLength - j)))])
                    bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx - (matchLength - j)))])
                    mismatches.append("|")
                }
            }
            
            if e == 1 as UInt { // mismatch
                aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx))])
                bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx))])
                mismatches.append(" ")
                aIdx += 1
                bIdx += 1
            }else if e == 2 as UInt { // A gap
                aChars.append(" ")
                bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx))])
                mismatches.append(" ")
                bIdx += 1
            }else if e == 3 as UInt { // B gap
                aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx))])
                bChars.append(" ")
                mismatches.append(" ")
                aIdx += 1
            }
            
            matchLength = 0
            start = false
        }
    }
    
    // leftover
    if matchLength > maxLength + 1 {
        for i in 0..<maxLength {
            aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx - (maxLength - i)))])
            bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx - (maxLength - i)))])
            mismatches.append("|")
        }
        
        aChars.append("…")
        bChars.append("…")
        mismatches.append(" ")
    }else{
        for i in 0..<matchLength {
            aChars.append(intToChar[Int(bitPattern: A.get(idx: aIdx - (matchLength - i)))])
            bChars.append(intToChar[Int(bitPattern: B.get(idx: bIdx - (matchLength - i)))])
            mismatches.append("|")
        }
    }
    
    return (String(aChars), String(bChars), String(mismatches))
}

public func editsToIdx(edits: BitVector) -> (sub: [Int], gapA: [Int], gapB: [Int]) {
    var sub: [Int] = []
    var gapA: [Int] = []
    var gapB: [Int] = []
    
    for i in 0..<edits.length {
        let e = edits.get(idx: i)
        
        if e == 1 as UInt { // mismatch
            sub.append(i)
        }else if e == 2 as UInt { // A gap
            gapA.append(i)
        }else if e == 3 as UInt { // B gap
            gapB.append(i)
        }
    }
    
    return (sub, gapA, gapB)
}
