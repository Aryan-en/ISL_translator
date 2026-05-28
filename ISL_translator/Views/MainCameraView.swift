import SwiftUI

// Combines the camera preview, hand skeleton overlay, and translation panel.
struct MainCameraView: View {

    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Top toolbar ────────────────────────────────────────────────
            HStack {
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isRunning ? .green : .gray)
                        .frame(width: 8, height: 8)
                        .shadow(color: viewModel.isRunning ? .green : .clear, radius: 4)
                    Text(viewModel.isRunning ? "Live" : "Stopped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Overlay", isOn: $viewModel.showOverlay)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .tint(.cyan)

                Button {
                    viewModel.toggleCamera()
                } label: {
                    Label(viewModel.isRunning ? "Stop" : "Start",
                          systemImage: viewModel.isRunning ? "stop.fill" : "play.fill")
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(viewModel.isRunning ? .red : .green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            // ── Main content ───────────────────────────────────────────────
            HStack(spacing: 0) {

                // Camera + overlay (left / primary)
                ZStack {
                    if viewModel.permissionDenied {
                        PermissionDeniedView()
                    } else {
                        CameraPreviewView(session: viewModel.captureSession)
                            // Mirror so it feels like looking in a mirror
                            .scaleEffect(x: -1, y: 1)

                        if viewModel.showOverlay && !viewModel.currentLandmarks.isEmpty {
                            HandOverlayView(landmarks: viewModel.currentLandmarks,
                                            isMirrored: false)  // already mirrored by scaleEffect
                        }

                        // Current gesture badge (top-left of camera)
                        VStack {
                            HStack {
                                CurrentGestureBadge(result: viewModel.currentResult)
                                Spacer()
                            }
                            Spacer()

                            // Confidence / hold meter at the bottom of camera
                            ConfidenceMeterView(
                                confidence: viewModel.currentResult.confidence,
                                holdProgress: viewModel.holdProgress,
                                gesture: viewModel.currentResult.gesture
                            )
                            .padding(10)
                        }
                    }
                }
                .frame(minWidth: 480)
                .clipShape(RoundedRectangle(cornerRadius: 0))

                Divider()

                // Translation panel (right)
                TranslationPanel(viewModel: viewModel)
                    .frame(width: 340)
            }
        }
        .background(.black)
    }
}

// MARK: - Current Gesture Badge

struct CurrentGestureBadge: View {
    let result: GestureResult

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: result.gesture.symbolName)
                .font(.title3)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 1) {
                Text(result.gesture.displayText)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(result.gesture.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .padding(12)
        .animation(.spring(response: 0.25), value: result.gesture.rawValue)
    }
}

// MARK: - Permission Denied Placeholder

struct PermissionDeniedView: View {
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                Image(systemName: "camera.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Camera Access Required")
                    .font(.title3.bold())
                Text("Open System Settings › Privacy & Security › Camera\nand enable access for ISL Translator.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
        }
    }
}
