import AVFoundation
import Vision

// MARK: - Camera Frame Coordinator
// Bridges AVCaptureVideoDataOutputSampleBufferDelegate (background queue)
// to the rest of the app.  Marked @unchecked Sendable because thread safety
// is handled manually via NSLock / DispatchQueue.
final class CameraFrameCoordinator: NSObject,
                                    AVCaptureVideoDataOutputSampleBufferDelegate,
                                    @unchecked Sendable {

    // Written once at init, never mutated – safe to access nonisolated
    nonisolated(unsafe) private let handTracker = HandTrackingService(maxHands: 1)
    nonisolated(unsafe) private let classifier  = GestureClassifier()

    // Prevents concurrent frame processing; cheaper than a DispatchQueue
    nonisolated(unsafe) private var processing = false
    private let lock = NSLock()

    // Callback invoked on the MainActor with each processed frame's result
    nonisolated(unsafe) var onFrame: ((GestureResult, [HandLandmarks]) -> Void)?

    // AVCaptureVideoDataOutputSampleBufferDelegate – called on the camera output queue
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Skip if still processing the previous frame
        lock.lock()
        guard !processing else { lock.unlock(); return }
        processing = true
        lock.unlock()

        defer {
            lock.lock()
            processing = false
            lock.unlock()
        }

        // Vision runs synchronously here on the camera output queue (~5-15 ms)
        let landmarks = handTracker.extractLandmarks(from: sampleBuffer)
        let result    = classifier.classify(landmarks: landmarks.first)

        // Deliver results to the main actor
        let r = result
        let l = landmarks
        Task { @MainActor [weak self] in
            self?.onFrame?(r, l)
        }
    }
}

// MARK: - Camera Service

@MainActor
final class CameraService: ObservableObject {

    @Published var permissionGranted = false
    @Published var error: String?

    private(set) var session = AVCaptureSession()
    let coordinator = CameraFrameCoordinator()

    private let sessionQueue = DispatchQueue(label: "isl.camera.session", qos: .userInitiated)
    private let outputQueue  = DispatchQueue(label: "isl.camera.output",  qos: .userInitiated)

    // MARK: Lifecycle

    func requestPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            permissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            permissionGranted = false
            error = "Camera access denied. Enable it in System Settings › Privacy & Security › Camera."
        }
    }

    func configure() async {
        guard permissionGranted else { return }
        await withCheckedContinuation { cont in
            sessionQueue.async { [weak self] in
                self?.setupSession()
                cont.resume()
            }
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // MARK: Private setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Prefer built-in / front-facing camera
        let device = frontCamera() ?? builtInCamera()
        guard let device else {
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(coordinator, queue: outputQueue)

        if session.canAddOutput(output) { session.addOutput(output) }

        // Mirror front-camera preview so it feels like a mirror
        if let conn = output.connection(with: .video), conn.isVideoMirroringSupported {
            conn.isVideoMirrored = false  // Vision coords stay consistent; we flip in UI
        }

        session.commitConfiguration()
    }

    private func frontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first
    }

    private func builtInCamera() -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices.first
    }
}
