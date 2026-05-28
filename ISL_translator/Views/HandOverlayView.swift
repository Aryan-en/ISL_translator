import SwiftUI

// Draws the hand skeleton landmarks on top of the camera preview.
// Coordinates are flipped from Vision space (bottom-left) to view space (top-left).
struct HandOverlayView: View {

    let landmarks: [HandLandmarks]
    let isMirrored: Bool

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for hand in landmarks {
                    drawHand(hand, ctx: &ctx, size: size)
                }
            }
        }
    }

    // MARK: - Drawing

    private func drawHand(_ hand: HandLandmarks, ctx: inout GraphicsContext, size: CGSize) {
        let pts = hand.allPoints.map { p in
            hand.displayPoint(p, in: size, mirrored: isMirrored)
        }

        // Draw bones
        for (a, b) in HandLandmarks.connections {
            guard a < pts.count, b < pts.count else { continue }
            var path = Path()
            path.move(to: pts[a])
            path.addLine(to: pts[b])
            ctx.stroke(path, with: .color(boneColor(for: a, b: b)), lineWidth: 2.5)
        }

        // Draw joints
        for (i, p) in pts.enumerated() {
            let r: CGFloat = i == 0 ? 6 : 4   // wrist is bigger
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            ctx.fill(Ellipse().path(in: rect), with: .color(jointColor(for: i)))
        }
    }

    // Colour fingers differently for clarity
    private func boneColor(for a: Int, b: Int) -> Color {
        let idx = max(a, b)
        switch idx {
        case 1...4:  return .yellow     // thumb
        case 5...8:  return .cyan       // index
        case 9...12: return .green      // middle
        case 13...16: return .orange    // ring
        case 17...20: return .pink      // little
        default:     return .white
        }
    }

    private func jointColor(for index: Int) -> Color {
        index == 0 ? .white : .white.opacity(0.9)
    }
}
