import SwiftUI
import AVFoundation

// NSViewRepresentable that hosts AVCaptureVideoPreviewLayer on macOS.
struct CameraPreviewView: NSViewRepresentable {

    let session: AVCaptureSession

    func makeNSView(context: Context) -> VideoPreviewNSView {
        let view = VideoPreviewNSView()
        view.previewLayer.session      = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: VideoPreviewNSView, context: Context) {
        // Session is already connected – nothing to update dynamically
    }
}

// NSView subclass that uses AVCaptureVideoPreviewLayer as its backing layer.
final class VideoPreviewNSView: NSView {

    override func makeBackingLayer() -> CALayer {
        AVCaptureVideoPreviewLayer()
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // Safe force-cast: makeBackingLayer() always returns this type
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }
}
