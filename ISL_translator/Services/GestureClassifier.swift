import Foundation

// MARK: - Hand Feature Vector

struct HandFeatures: Sendable {
    let thumbExtended: Bool
    let indexExtended: Bool
    let middleExtended: Bool
    let ringExtended: Bool
    let littleExtended: Bool

    let thumbSideways: Bool
    let thumbTouchesIndex: Bool
    let thumbTouchesMiddle: Bool
    let thumbTouchesLittle: Bool
    let indexMiddleSeparated: Bool
    let indexHorizontal: Bool
    let indexCurled: Bool

    var extendedCount: Int {
        [indexExtended, middleExtended, ringExtended, littleExtended].filter { $0 }.count
    }
    var allCurled: Bool {
        !indexExtended && !middleExtended && !ringExtended && !littleExtended
    }
    var allExtended: Bool {
        indexExtended && middleExtended && ringExtended && littleExtended
    }
}

// MARK: - Gesture Classifier

struct GestureClassifier: Sendable {

    func classify(landmarks: HandLandmarks?) -> GestureResult {
        guard let lm = landmarks else {
            return GestureResult(gesture: .unknown, confidence: 0, timestamp: .now)
        }
        let features = computeFeatures(lm)
        return bestMatch(features: features)
    }

    // MARK: - Feature Computation

    private func computeFeatures(_ lm: HandLandmarks) -> HandFeatures {
        let palm = lm.palmSize.clamped(to: 0.01...1)

        let thumbExt  = isExtended(wrist: lm.wrist, mcp: lm.thumbCMC,  pip: lm.thumbMP,   tip: lm.thumbTip,  palm: palm, ratio: 1.4)
        let indexExt  = isExtended(wrist: lm.wrist, mcp: lm.indexMCP,  pip: lm.indexPIP,  tip: lm.indexTip,  palm: palm, ratio: 1.3)
        let midExt    = isExtended(wrist: lm.wrist, mcp: lm.middleMCP, pip: lm.middlePIP, tip: lm.middleTip, palm: palm, ratio: 1.3)
        let ringExt   = isExtended(wrist: lm.wrist, mcp: lm.ringMCP,   pip: lm.ringPIP,   tip: lm.ringTip,   palm: palm, ratio: 1.3)
        let littleExt = isExtended(wrist: lm.wrist, mcp: lm.littleMCP, pip: lm.littlePIP, tip: lm.littleTip, palm: palm, ratio: 1.3)

        let thumbDX   = abs(lm.thumbTip.x - lm.wrist.x)
        let thumbDY   = abs(lm.thumbTip.y - lm.wrist.y)
        let thumbSide = thumbDX > thumbDY * 0.85

        let tIdx  = dist(lm.thumbTip, lm.indexTip)  < palm * 0.35
        let tMid  = dist(lm.thumbTip, lm.middleTip) < palm * 0.35
        let tLit  = dist(lm.thumbTip, lm.littleTip) < palm * 0.35

        let iDX       = abs(lm.indexTip.x - lm.indexMCP.x)
        let iDY       = abs(lm.indexTip.y - lm.indexMCP.y)
        let indexHoriz = iDX > iDY * 0.9

        let imDist     = dist(lm.indexTip, lm.middleTip)
        let indexMidSep = imDist > palm * 0.55

        let indexCurl = lm.indexTip.y < lm.indexPIP.y - palm * 0.05

        return HandFeatures(
            thumbExtended: thumbExt,
            indexExtended: indexExt,
            middleExtended: midExt,
            ringExtended: ringExt,
            littleExtended: littleExt,
            thumbSideways: thumbSide,
            thumbTouchesIndex: tIdx,
            thumbTouchesMiddle: tMid,
            thumbTouchesLittle: tLit,
            indexMiddleSeparated: indexMidSep,
            indexHorizontal: indexHoriz,
            indexCurled: indexCurl
        )
    }

    private func isExtended(wrist: CGPoint, mcp: CGPoint, pip: CGPoint, tip: CGPoint,
                             palm: CGFloat, ratio: CGFloat) -> Bool {
        dist(wrist, tip) > dist(wrist, mcp) * ratio
    }

    // MARK: - Pattern Matching

    private func bestMatch(features f: HandFeatures) -> GestureResult {
        let candidates = allGestureScores(features: f)
        guard let top = candidates.max(by: { $0.1 < $1.1 }), top.1 >= 0.55 else {
            return GestureResult(gesture: .unknown, confidence: 0, timestamp: .now)
        }
        return GestureResult(gesture: top.0, confidence: top.1, timestamp: .now)
    }

    private func allGestureScores(features f: HandFeatures) -> [(ISLGesture, Float)] {
        // Score = proportion of matched feature weight out of total weight
        func s(_ conditions: [(Bool, Float)]) -> Float {
            let total   = conditions.reduce(0) { $0 + $1.1 }
            let matched = conditions.filter { $0.0 }.reduce(0) { $0 + $1.1 }
            return total > 0 ? Float(matched / total) : 0
        }

        let ext = f.extendedCount
        let allCurl = f.allCurled
        let allExt  = f.allExtended

        return [
            // ── LETTERS ────────────────────────────────────────────────────
            (.A, s([(!f.indexExtended, 1.0), (!f.middleExtended, 1.0), (!f.ringExtended, 0.8),
                    (!f.littleExtended, 0.8), (f.thumbSideways, 1.2), (!f.thumbTouchesIndex, 0.5)])),

            (.B, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                    (f.littleExtended, 1.0), (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.6)])),

            (.C, s([(allCurl, 1.0), (f.thumbSideways, 0.8), (ext == 0, 0.8),
                    (!f.thumbTouchesIndex, 0.5)])),

            (.D, s([(f.indexExtended, 1.2), (!f.middleExtended, 0.9), (!f.ringExtended, 0.8),
                    (!f.littleExtended, 0.8), (f.thumbTouchesMiddle, 1.0), (!f.indexHorizontal, 0.7)])),

            (.E, s([(allCurl, 1.5), (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.6)])),

            (.F, s([(f.thumbTouchesIndex, 1.2), (f.middleExtended, 0.9), (f.ringExtended, 0.9),
                    (f.littleExtended, 0.9), (!f.indexExtended, 0.7)])),

            (.G, s([(f.indexExtended, 1.0), (f.indexHorizontal, 1.2), (!f.middleExtended, 0.8),
                    (!f.ringExtended, 0.7), (!f.littleExtended, 0.7), (f.thumbSideways, 0.8)])),

            (.H, s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.indexHorizontal, 1.0),
                    (!f.ringExtended, 0.7), (!f.littleExtended, 0.7)])),

            (.I, s([(f.littleExtended, 1.2), (!f.indexExtended, 1.0), (!f.middleExtended, 1.0),
                    (!f.ringExtended, 0.8), (!f.thumbExtended, 0.5)])),

            (.K, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.thumbExtended, 0.9),
                    (!f.ringExtended, 0.8), (!f.littleExtended, 0.8), (!f.indexHorizontal, 0.6)])),

            (.L, s([(f.indexExtended, 1.0), (f.thumbSideways, 1.2), (f.thumbExtended, 0.9),
                    (!f.middleExtended, 0.9), (!f.ringExtended, 0.8), (!f.littleExtended, 0.8),
                    (!f.indexHorizontal, 0.7)])),

            (.M, s([(allCurl, 1.0), (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.5), (ext == 0, 1.0)])),
            (.N, s([(allCurl, 1.0), (!f.thumbExtended, 0.8), (ext == 0, 1.0)])),

            (.O, s([(f.thumbTouchesIndex, 1.0), (!f.indexExtended, 0.7), (!f.middleExtended, 0.7),
                    (!f.ringExtended, 0.5), (!f.littleExtended, 0.5), (ext == 0, 0.8)])),

            (.R, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (!f.indexMiddleSeparated, 1.0),
                    (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),

            (.S, s([(allCurl, 1.2), (f.thumbExtended, 0.6), (!f.thumbSideways, 0.7)])),
            (.T, s([(allCurl, 0.9), (f.thumbTouchesIndex, 0.8), (f.thumbTouchesMiddle, 0.8)])),

            (.U, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (!f.indexMiddleSeparated, 1.2),
                    (!f.ringExtended, 0.9), (!f.littleExtended, 0.9), (!f.indexHorizontal, 0.6)])),

            (.V, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.indexMiddleSeparated, 1.2),
                    (!f.ringExtended, 0.9), (!f.littleExtended, 0.9)])),

            (.W, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                    (!f.littleExtended, 0.9), (!f.thumbSideways, 0.5)])),

            (.X, s([(f.indexCurled, 1.2), (!f.middleExtended, 0.9), (!f.ringExtended, 0.8),
                    (!f.littleExtended, 0.8)])),

            (.Y, s([(f.thumbExtended, 1.0), (f.littleExtended, 1.0), (f.thumbSideways, 0.8),
                    (!f.indexExtended, 1.0), (!f.middleExtended, 1.0), (!f.ringExtended, 0.9)])),

            // ── NUMBERS ────────────────────────────────────────────────────
            (.zero,  s([(f.thumbTouchesIndex, 1.2), (ext == 0, 1.0), (!f.thumbSideways, 0.5)])),
            (.one,   s([(f.indexExtended, 1.2), (!f.middleExtended, 1.0), (!f.ringExtended, 0.9),
                        (!f.littleExtended, 0.9), (!f.indexHorizontal, 0.7)])),
            (.two,   s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.indexMiddleSeparated, 1.0),
                        (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),
            (.three, s([(f.thumbExtended, 1.0), (f.indexExtended, 1.0), (f.middleExtended, 1.0),
                        (!f.ringExtended, 0.9), (!f.littleExtended, 0.9), (f.thumbSideways, 0.7)])),
            (.four,  s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                        (f.littleExtended, 1.0), (!f.thumbExtended, 0.8)])),
            (.five,  s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                        (f.littleExtended, 1.0), (f.thumbExtended, 1.0), (f.thumbSideways, 0.8)])),
            (.six,   s([(f.thumbTouchesLittle, 1.2), (f.indexExtended, 0.8), (f.middleExtended, 0.8),
                        (f.ringExtended, 0.8)])),
            (.seven, s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.thumbExtended, 0.9),
                        (!f.ringExtended, 0.8), (!f.littleExtended, 0.7)])),
            (.eight, s([(f.thumbTouchesMiddle, 1.2), (f.indexExtended, 0.7), (f.ringExtended, 0.6),
                        (f.littleExtended, 0.6)])),
            (.nine,  s([(f.thumbTouchesIndex, 1.0), (f.middleExtended, 0.6), (f.ringExtended, 0.5),
                        (f.littleExtended, 0.5)])),

            // ── WORDS ───────────────────────────────────────────────────────
            (.hello,    s([(allExt, 1.5), (f.thumbExtended, 1.0), (f.thumbSideways, 0.8),
                           (f.indexMiddleSeparated, 0.7)])),
            (.thankYou, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                           (f.littleExtended, 1.0), (!f.indexMiddleSeparated, 0.8), (!f.thumbSideways, 0.6)])),
            (.yes,      s([(allCurl, 1.2), (!f.thumbSideways, 0.8), (!f.thumbExtended, 0.6)])),
            (.no,       s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.indexHorizontal, 1.1),
                           (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),
            (.help,     s([(allCurl, 1.0), (f.thumbSideways, 1.0)])),
            (.water,    s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                           (!f.littleExtended, 0.8), (!f.thumbExtended, 0.6)])),
            (.food,     s([(allExt, 1.0), (!f.thumbSideways, 0.7), (!f.indexMiddleSeparated, 0.8)])),
            (.sorry,    s([(allCurl, 1.0), (f.thumbExtended, 0.7), (!f.thumbSideways, 0.7)])),
            (.iLoveYou, s([(f.thumbExtended, 1.0), (f.indexExtended, 1.0), (f.littleExtended, 1.0),
                           (!f.middleExtended, 1.0), (!f.ringExtended, 1.0), (f.thumbSideways, 0.6)])),
        ]
    }
}

// MARK: - Clamping helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
