import Foundation

// MARK: - Hand Feature Vector

struct HandFeatures: Sendable {
    // Finger extension (true = extended outward)
    let thumbExtended: Bool
    let indexExtended: Bool
    let middleExtended: Bool
    let ringExtended: Bool
    let littleExtended: Bool

    // Additional geometric features
    let thumbSideways: Bool          // thumb pointing left/right more than up
    let thumbTouchesIndex: Bool      // thumbTip close to indexTip
    let thumbTouchesMiddle: Bool     // thumbTip close to middleTip
    let thumbTouchesLittle: Bool     // thumbTip close to littleTip
    let indexMiddleSeparated: Bool   // V sign – wide gap between index & middle
    let indexHorizontal: Bool        // index pointing sideways more than up
    let indexCurled: Bool            // index tip below index PIP (hooked)

    // Derived counts
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

    // Returns the best matching gesture and its confidence for the first hand found.
    nonisolated func classify(landmarks: HandLandmarks?) -> GestureResult {
        guard let lm = landmarks else {
            return GestureResult(gesture: .unknown, confidence: 0, timestamp: .now)
        }
        let features = computeFeatures(lm)
        return bestMatch(features: features)
    }

    // MARK: - Feature Computation

    nonisolated private func computeFeatures(_ lm: HandLandmarks) -> HandFeatures {
        let palm = lm.palmSize.clamped(to: 0.01...1)

        // Finger extension: tip significantly farther from wrist than MCP
        let thumbExt  = isExtended(wrist: lm.wrist, mcp: lm.thumbCMC, pip: lm.thumbMP, tip: lm.thumbTip, palm: palm, ratio: 1.4)
        let indexExt  = isExtended(wrist: lm.wrist, mcp: lm.indexMCP, pip: lm.indexPIP, tip: lm.indexTip, palm: palm, ratio: 1.3)
        let midExt    = isExtended(wrist: lm.wrist, mcp: lm.middleMCP, pip: lm.middlePIP, tip: lm.middleTip, palm: palm, ratio: 1.3)
        let ringExt   = isExtended(wrist: lm.wrist, mcp: lm.ringMCP, pip: lm.ringPIP, tip: lm.ringTip, palm: palm, ratio: 1.3)
        let littleExt = isExtended(wrist: lm.wrist, mcp: lm.littleMCP, pip: lm.littlePIP, tip: lm.littleTip, palm: palm, ratio: 1.3)

        // Thumb direction
        let thumbDX = abs(lm.thumbTip.x - lm.wrist.x)
        let thumbDY = abs(lm.thumbTip.y - lm.wrist.y)
        let thumbSide = thumbDX > thumbDY * 0.85

        // Proximity: two landmarks within threshold * palmSize
        let tIdx  = dist(lm.thumbTip, lm.indexTip)  < palm * 0.35
        let tMid  = dist(lm.thumbTip, lm.middleTip) < palm * 0.35
        let tLit  = dist(lm.thumbTip, lm.littleTip) < palm * 0.35

        // Index horizontal: tip x-displacement > y-displacement from MCP
        let iDX = abs(lm.indexTip.x - lm.indexMCP.x)
        let iDY = abs(lm.indexTip.y - lm.indexMCP.y)
        let indexHoriz = iDX > iDY * 0.9

        // V vs U: distance between index & middle tips relative to palm
        let imDist = dist(lm.indexTip, lm.middleTip)
        let indexMidSep = imDist > palm * 0.55

        // X / hooked index: tip y < PIP y (in Vision space, y=0 bottom, y=1 top)
        // So "hooked" means tip is lower than PIP
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

    // Extension test: compare tip vs MCP distance from wrist; also use PIP as sanity check
    nonisolated private func isExtended(
        wrist: CGPoint, mcp: CGPoint, pip: CGPoint, tip: CGPoint,
        palm: CGFloat, ratio: CGFloat
    ) -> Bool {
        let mcpDist = dist(wrist, mcp)
        let tipDist = dist(wrist, tip)
        return tipDist > mcpDist * ratio
    }

    // MARK: - Pattern Matching

    nonisolated private func bestMatch(features f: HandFeatures) -> GestureResult {
        let candidates = allGestureScores(features: f)
        guard let top = candidates.max(by: { $0.1 < $1.1 }) else {
            return GestureResult(gesture: .unknown, confidence: 0, timestamp: .now)
        }
        // Require a minimum confidence threshold
        guard top.1 >= 0.55 else {
            return GestureResult(gesture: .unknown, confidence: top.1, timestamp: .now)
        }
        return GestureResult(gesture: top.0, confidence: top.1, timestamp: .now)
    }

    // Returns (gesture, score 0-1) for all known gestures
    nonisolated private func allGestureScores(features f: HandFeatures) -> [(ISLGesture, Float)] {

        // Helper: score is proportion of matched features out of total weight
        func s(_ conditions: [(Bool, Float)]) -> Float {
            let totalWeight = conditions.reduce(0) { $0 + $1.1 }
            let matched = conditions.filter { $0.0 }.reduce(0) { $0 + $1.1 }
            guard totalWeight > 0 else { return 0 }
            return Float(matched / totalWeight)
        }

        return [
            // ── LETTERS ──────────────────────────────────────────────────────

            // A: Fist, thumb resting on side of index finger (sideways, not over)
            (.A, s([(!f.indexExtended, 1.0), (!f.middleExtended, 1.0), (!f.ringExtended, 0.8), (!f.littleExtended, 0.8),
                    (f.thumbSideways, 1.2), (!f.thumbTouchesIndex, 0.5)])),

            // B: Four fingers extended, thumb tucked across palm
            (.B, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0), (f.littleExtended, 1.0),
                    (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.6)])),

            // C: Curved hand – all five slightly curled, none fully extended
            (.C, s([(!f.indexExtended, 0.6), (!f.middleExtended, 0.6), (!f.ringExtended, 0.6), (!f.littleExtended, 0.6),
                    (f.thumbSideways, 0.8), (!f.thumbTouchesIndex, 0.5), (f.extendedCount == 0, 0.8)])),

            // D: Index up, thumb touching middle
            (.D, s([(f.indexExtended, 1.2), (!f.middleExtended, 0.9), (!f.ringExtended, 0.8), (!f.littleExtended, 0.8),
                    (f.thumbTouchesMiddle, 1.0), (!f.indexHorizontal, 0.7)])),

            // E: All fingers curled/bent, thumb tucked under
            (.E, s([(f.allCurled, 1.5), (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.6)])),

            // F: Thumb + index touching circle, middle/ring/little extended
            (.F, s([(f.thumbTouchesIndex, 1.2), (f.middleExtended, 0.9), (f.ringExtended, 0.9), (f.littleExtended, 0.9),
                    (!f.indexExtended, 0.7)])),

            // G: Index pointing horizontal, thumb parallel
            (.G, s([(f.indexExtended, 1.0), (f.indexHorizontal, 1.2), (!f.middleExtended, 0.8),
                    (!f.ringExtended, 0.7), (!f.littleExtended, 0.7), (f.thumbSideways, 0.8)])),

            // H: Index + middle horizontal, others curled
            (.H, s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.indexHorizontal, 1.0),
                    (!f.ringExtended, 0.7), (!f.littleExtended, 0.7)])),

            // I: Only little finger extended
            (.I, s([(f.littleExtended, 1.2), (!f.indexExtended, 1.0), (!f.middleExtended, 1.0),
                    (!f.ringExtended, 0.8), (!f.thumbExtended, 0.5)])),

            // K: Index + middle + thumb extended, ring + little curled
            (.K, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.thumbExtended, 0.9),
                    (!f.ringExtended, 0.8), (!f.littleExtended, 0.8), (!f.indexHorizontal, 0.6)])),

            // L: Index pointing up, thumb extended sideways (L-shape)
            (.L, s([(f.indexExtended, 1.0), (f.thumbSideways, 1.2), (f.thumbExtended, 0.9),
                    (!f.middleExtended, 0.9), (!f.ringExtended, 0.8), (!f.littleExtended, 0.8),
                    (!f.indexHorizontal, 0.7)])),

            // M: Three fingers (index, middle, ring) bent over thumb, little curled
            (.M, s([(f.allCurled, 1.0), (!f.thumbExtended, 0.8), (!f.thumbSideways, 0.5), (f.extendedCount == 0, 1.0)])),

            // N: Two fingers over thumb (similar to M, hard to fully distinguish statically)
            (.N, s([(f.allCurled, 1.0), (!f.thumbExtended, 0.8), (f.extendedCount == 0, 1.0)])),

            // O: All fingers form a circle/O with thumb
            (.O, s([(f.thumbTouchesIndex, 1.0), (!f.indexExtended, 0.7), (!f.middleExtended, 0.7),
                    (!f.ringExtended, 0.5), (!f.littleExtended, 0.5), (f.extendedCount == 0, 0.8)])),

            // R: Index + middle extended and crossed (together, not spread)
            (.R, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (!f.indexMiddleSeparated, 1.0),
                    (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),

            // S: Fist, thumb over fingers
            (.S, s([(f.allCurled, 1.2), (f.thumbExtended, 0.6), (!f.thumbSideways, 0.7)])),

            // T: Thumb between index and middle (fist with thumb protruding between i/m)
            (.T, s([(f.allCurled, 0.9), (f.thumbTouchesIndex, 0.8), (f.thumbTouchesMiddle, 0.8)])),

            // U: Index + middle extended together (not spread)
            (.U, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (!f.indexMiddleSeparated, 1.2),
                    (!f.ringExtended, 0.9), (!f.littleExtended, 0.9), (!f.indexHorizontal, 0.6)])),

            // V: Index + middle spread (peace sign)
            (.V, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.indexMiddleSeparated, 1.2),
                    (!f.ringExtended, 0.9), (!f.littleExtended, 0.9)])),

            // W: Three fingers up (index + middle + ring), little curled, thumb tucked
            (.W, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                    (!f.littleExtended, 0.9), (!f.thumbSideways, 0.5)])),

            // X: Index hooked/bent (curl index, others closed)
            (.X, s([(f.indexCurled, 1.2), (!f.middleExtended, 0.9), (!f.ringExtended, 0.8),
                    (!f.littleExtended, 0.8)])),

            // Y: Thumb + little finger extended (shaka / hang loose)
            (.Y, s([(f.thumbExtended, 1.0), (f.littleExtended, 1.0), (f.thumbSideways, 0.8),
                    (!f.indexExtended, 1.0), (!f.middleExtended, 1.0), (!f.ringExtended, 0.9)])),

            // ── NUMBERS ──────────────────────────────────────────────────────

            // 0: Like O (thumb touches index, others slightly curled)
            (.zero, s([(f.thumbTouchesIndex, 1.2), (f.extendedCount == 0, 1.0), (!f.thumbSideways, 0.5)])),

            // 1: Only index extended
            (.one, s([(f.indexExtended, 1.2), (!f.middleExtended, 1.0), (!f.ringExtended, 0.9),
                      (!f.littleExtended, 0.9), (!f.indexHorizontal, 0.7)])),

            // 2: Index + middle spread (same as V)
            (.two, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.indexMiddleSeparated, 1.0),
                      (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),

            // 3: Thumb + index + middle (three-finger salute)
            (.three, s([(f.thumbExtended, 1.0), (f.indexExtended, 1.0), (f.middleExtended, 1.0),
                        (!f.ringExtended, 0.9), (!f.littleExtended, 0.9), (f.thumbSideways, 0.7)])),

            // 4: All four fingers up, thumb tucked
            (.four, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                       (f.littleExtended, 1.0), (!f.thumbExtended, 0.8)])),

            // 5: All five open (same as Hello)
            (.five, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                       (f.littleExtended, 1.0), (f.thumbExtended, 1.0), (f.thumbSideways, 0.8)])),

            // 6: Thumb + pinky touching, index/middle/ring extended
            (.six, s([(f.thumbTouchesLittle, 1.2), (f.indexExtended, 0.8), (f.middleExtended, 0.8),
                      (f.ringExtended, 0.8)])),

            // 7: Four fingers + thumb spread (all up), ring tucked slightly
            (.seven, s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.thumbExtended, 0.9),
                        (!f.ringExtended, 0.8), (!f.littleExtended, 0.7)])),

            // 8: Middle + thumb touching, others spread
            (.eight, s([(f.thumbTouchesMiddle, 1.2), (f.indexExtended, 0.7), (f.ringExtended, 0.6),
                        (f.littleExtended, 0.6)])),

            // 9: Index + thumb touching (like O but index more extended)
            (.nine, s([(f.thumbTouchesIndex, 1.0), (f.middleExtended, 0.6), (f.ringExtended, 0.5),
                       (f.littleExtended, 0.5)])),

            // ── COMMON WORDS ─────────────────────────────────────────────────

            // Hello: Open hand, all five fingers extended and spread
            (.hello, s([(f.allExtended, 1.5), (f.thumbExtended, 1.0), (f.thumbSideways, 0.8),
                        (f.indexMiddleSeparated, 0.7)])),

            // Thank You: Flat hand (B-shape), fingers together
            (.thankYou, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                           (f.littleExtended, 1.0), (!f.indexMiddleSeparated, 0.8), (!f.thumbSideways, 0.6)])),

            // Yes: Fist with nodding motion (static: fist)
            (.yes, s([(f.allCurled, 1.2), (!f.thumbSideways, 0.8), (!f.thumbExtended, 0.6)])),

            // No: Index + middle horizontal (wave/wag)
            (.no, s([(f.indexExtended, 0.9), (f.middleExtended, 0.9), (f.indexHorizontal, 1.1),
                     (!f.ringExtended, 0.8), (!f.littleExtended, 0.8)])),

            // Help: Fist (A shape) – simplified
            (.help, s([(f.allCurled, 1.0), (f.thumbSideways, 1.0)])),

            // Water: W shape (index + middle + ring up)
            (.water, s([(f.indexExtended, 1.0), (f.middleExtended, 1.0), (f.ringExtended, 1.0),
                        (!f.littleExtended, 0.8), (!f.thumbExtended, 0.6)])),

            // Food: Flat hand toward mouth (B shape)
            (.food, s([(f.allExtended, 1.0), (!f.thumbSideways, 0.7), (!f.indexMiddleSeparated, 0.8)])),

            // Sorry: S shape (fist, thumb across)
            (.sorry, s([(f.allCurled, 1.0), (f.thumbExtended, 0.7), (!f.thumbSideways, 0.7)])),

            // I Love You: Thumb + index + little extended
            (.iLoveYou, s([(f.thumbExtended, 1.0), (f.indexExtended, 1.0), (f.littleExtended, 1.0),
                           (!f.middleExtended, 1.0), (!f.ringExtended, 1.0), (f.thumbSideways, 0.6)])),
        ]
    }
}

// MARK: - Comparable clamping helper

extension Comparable {
    nonisolated func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
