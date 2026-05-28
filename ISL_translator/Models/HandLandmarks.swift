import Foundation
import Vision

// MARK: - Hand Landmarks

struct HandLandmarks: Sendable {
    let wrist: CGPoint
    let thumbCMC: CGPoint
    let thumbMP: CGPoint
    let thumbIP: CGPoint
    let thumbTip: CGPoint
    let indexMCP: CGPoint
    let indexPIP: CGPoint
    let indexDIP: CGPoint
    let indexTip: CGPoint
    let middleMCP: CGPoint
    let middlePIP: CGPoint
    let middleDIP: CGPoint
    let middleTip: CGPoint
    let ringMCP: CGPoint
    let ringPIP: CGPoint
    let ringDIP: CGPoint
    let ringTip: CGPoint
    let littleMCP: CGPoint
    let littlePIP: CGPoint
    let littleDIP: CGPoint
    let littleTip: CGPoint
    let chirality: String  // "Left" or "Right"

    // nonisolated: called from background queues in HandTrackingService
    init?(from observation: VNHumanHandPoseObservation) {
        guard
            let w = try? observation.recognizedPoint(.wrist),
            w.confidence > 0.3
        else { return nil }

        func pt(_ joint: VNHumanHandPoseObservation.JointName) -> CGPoint {
            guard let p = try? observation.recognizedPoint(joint), p.confidence > 0.15 else {
                return w.location
            }
            return p.location
        }

        wrist      = w.location
        thumbCMC   = pt(.thumbCMC)
        thumbMP    = pt(.thumbMP)
        thumbIP    = pt(.thumbIP)
        thumbTip   = pt(.thumbTip)
        indexMCP   = pt(.indexMCP)
        indexPIP   = pt(.indexPIP)
        indexDIP   = pt(.indexDIP)
        indexTip   = pt(.indexTip)
        middleMCP  = pt(.middleMCP)
        middlePIP  = pt(.middlePIP)
        middleDIP  = pt(.middleDIP)
        middleTip  = pt(.middleTip)
        ringMCP    = pt(.ringMCP)
        ringPIP    = pt(.ringPIP)
        ringDIP    = pt(.ringDIP)
        ringTip    = pt(.ringTip)
        littleMCP  = pt(.littleMCP)
        littlePIP  = pt(.littlePIP)
        littleDIP  = pt(.littleDIP)
        littleTip  = pt(.littleTip)
        chirality  = observation.chirality == .right ? "Right" : "Left"
    }

    // All 21 landmarks as ordered array (Vision standard order)
    var allPoints: [CGPoint] {
        [wrist,
         thumbCMC, thumbMP, thumbIP, thumbTip,
         indexMCP, indexPIP, indexDIP, indexTip,
         middleMCP, middlePIP, middleDIP, middleTip,
         ringMCP, ringPIP, ringDIP, ringTip,
         littleMCP, littlePIP, littleDIP, littleTip]
    }

    // Skeleton connections for drawing
    static let connections: [(Int, Int)] = [
        (0, 1), (1, 2), (2, 3), (3, 4),
        (0, 5), (5, 6), (6, 7), (7, 8),
        (0, 9), (9, 10), (10, 11), (11, 12),
        (0, 13), (13, 14), (14, 15), (15, 16),
        (0, 17), (17, 18), (18, 19), (19, 20),
        (5, 9), (9, 13), (13, 17)
    ]

    // Approximate hand size (wrist to middle MCP distance).
    // Marked nonisolated so GestureClassifier can call it from a background queue.
    var palmSize: CGFloat { dist(wrist, middleMCP) }

    // Convert Vision point (bottom-left origin, 0-1) to view coordinates (top-left origin)
    func displayPoint(_ p: CGPoint, in size: CGSize, mirrored: Bool = true) -> CGPoint {
        let x = mirrored ? (1 - p.x) * size.width : p.x * size.width
        let y = (1 - p.y) * size.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Geometry helpers (free functions — no actor isolation)

func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
}

func angle(_ a: CGPoint, _ vertex: CGPoint, _ b: CGPoint) -> CGFloat {
    let v1 = CGPoint(x: a.x - vertex.x, y: a.y - vertex.y)
    let v2 = CGPoint(x: b.x - vertex.x, y: b.y - vertex.y)
    let dot = v1.x * v2.x + v1.y * v2.y
    let m1  = sqrt(v1.x * v1.x + v1.y * v1.y)
    let m2  = sqrt(v2.x * v2.x + v2.y * v2.y)
    guard m1 > 0, m2 > 0 else { return 0 }
    return acos(max(-1, min(1, dot / (m1 * m2))))
}
