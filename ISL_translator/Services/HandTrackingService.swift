import Vision
import AVFoundation
import CoreImage

// HandTrackingService runs Vision hand-pose detection.
// All methods are nonisolated so they can be called from background queues
// without actor-isolation errors (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
struct HandTrackingService: Sendable {

    // Maximum number of hands to detect simultaneously
    private let maxHands: Int

    init(maxHands: Int = 2) {
        self.maxHands = maxHands
    }

    // Processes a CMSampleBuffer and returns up to maxHands HandLandmarks.
    // Called synchronously on whichever queue the caller chooses.
    nonisolated func extractLandmarks(from sampleBuffer: CMSampleBuffer) -> [HandLandmarks] {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = maxHands

        // Use .upMirrored for front-facing camera to get natural coordinates
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                            orientation: .up,
                                            options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let results = request.results, !results.isEmpty else { return [] }

        return results.compactMap { HandLandmarks(from: $0) }
    }

    // Convenience: extract from CVPixelBuffer (useful when buffer has been retained)
    nonisolated func extractLandmarks(from pixelBuffer: CVPixelBuffer) -> [HandLandmarks] {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = maxHands

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let results = request.results, !results.isEmpty else { return [] }
        return results.compactMap { HandLandmarks(from: $0) }
    }
}
