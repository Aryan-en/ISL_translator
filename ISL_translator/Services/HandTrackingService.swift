import Vision
import AVFoundation

// Runs VNDetectHumanHandPoseRequest synchronously on whichever queue calls it.
// All methods are plain (no actor isolation) — safe to call from any background queue.
struct HandTrackingService: Sendable {

    private let maxHands: Int

    init(maxHands: Int = 2) {
        self.maxHands = maxHands
    }

    func extractLandmarks(from sampleBuffer: CMSampleBuffer) -> [HandLandmarks] {
        let request = makeRequest()
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                            orientation: .up,
                                            options: [:])
        return perform(request, with: handler)
    }

    func extractLandmarks(from pixelBuffer: CVPixelBuffer) -> [HandLandmarks] {
        let request = makeRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        return perform(request, with: handler)
    }

    // MARK: - Private

    private func makeRequest() -> VNDetectHumanHandPoseRequest {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = maxHands
        return r
    }

    private func perform(_ request: VNDetectHumanHandPoseRequest,
                         with handler: VNImageRequestHandler) -> [HandLandmarks] {
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        return (request.results ?? []).compactMap { HandLandmarks(from: $0) }
    }
}
