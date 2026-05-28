import AVFoundation

// MARK: - Camera Frame Coordinator
// Bridges AVCaptureVideoDataOutputSampleBufferDelegate (background queue) to the ViewModel.
// @unchecked Sendable: thread safety is managed manually with NSLock.
final class CameraFrameCoordinator: NSObject,
                                    AVCaptureVideoDataOutputSampleBufferDelegate,
                                    @unchecked Sendable {

    // Immutable after init; HandTrackingService + GestureClassifier are value-type Sendable
    private let handTracker = HandTrackingService(maxHands: 1)
    private let classifier  = GestureClassifier()

    // NSLock protects the processing flag across the camera output queue
    private let lock = NSLock()
    private var processing = false

    // Set from @MainActor (CameraViewModel); read on the camera output queue
    var onFrame: ((GestureResult, [HandLandmarks]) -> Void)?

    // Called on the camera output queue (background)
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        lock.lock()
        guard !processing else { lock.unlock(); return }
        processing = true
        lock.unlock()

        defer {
            lock.lock()
            processing = false
            lock.unlock()
        }

        // Vision runs synchronously here (~5-15 ms)
        let landmarks = handTracker.extractLandmarks(from: sampleBuffer)
        let result    = classifier.classify(landmarks: landmarks.first)

        let cb = onFrame
        DispatchQueue.main.async {
            cb?(result, landmarks)
        }
    }
}

// MARK: - Camera Service
// Plain class (no actor isolation) — used exclusively from @MainActor CameraViewModel.
// AVCaptureSession setup and start/stop run on a dedicated background queue.
final class CameraService: NSObject {

    let coordinator = CameraFrameCoordinator()
    private(set) var session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "isl.camera.session", qos: .userInitiated)
    private let outputQueue  = DispatchQueue(label: "isl.camera.output",  qos: .userInitiated)

    // Async configure: runs AVCaptureSession setup on sessionQueue, awaits completion
    func configure() async {
        await withCheckedContinuation { cont in
            sessionQueue.async { [weak self] in
                self?.setupSession()
                cont.resume()
            }
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Private setup (runs on sessionQueue)

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = frontCamera() ?? builtInCamera() else {
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
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(coordinator, queue: outputQueue)

        if session.canAddOutput(output) { session.addOutput(output) }

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
        // Fallback: any available camera (built-in or external) on macOS
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices.first ?? AVCaptureDevice.default(for: .video)
    }
}
