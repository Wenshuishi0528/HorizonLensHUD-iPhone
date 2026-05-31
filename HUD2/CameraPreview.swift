import SwiftUI
import AVFoundation

/// 简化版相机预览（修复：显式使用 AVCaptureVideoPreviewLayer，而非 CALayer）
struct CameraPreview: UIViewRepresentable {
    let orientation: AVCaptureVideoOrientation
    
    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        // 传入预览层的 session，避免 v.layer（CALayer）类型不匹配问题
        context.coordinator.configure(on: v.previewLayer.session)
        return v
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 显式传入 AVCaptureVideoPreviewLayer，避免类型转换错误
        context.coordinator.updateOrientation(orientation, on: uiView.previewLayer)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    // MARK: - Coordinator
    
    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let queue = DispatchQueue(label: "camera.queue")
        private var videoOutput: AVCaptureVideoDataOutput?
        
        func configure(on sessionRef: AVCaptureSession?) {
            guard let sessionRef = sessionRef else { return }
            // 仅当外部 session 未设置时，使用内置配置
            if sessionRef.inputs.isEmpty && sessionRef.outputs.isEmpty {
                sessionRef.beginConfiguration()
                sessionRef.sessionPreset = .high
                
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      sessionRef.canAddInput(input) else {
                    sessionRef.commitConfiguration()
                    return
                }
                sessionRef.addInput(input)
                
                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: queue)
                if sessionRef.canAddOutput(output) {
                    sessionRef.addOutput(output)
                    self.videoOutput = output
                }
                
                sessionRef.commitConfiguration()
                sessionRef.startRunning()
            }
        }
        
        func updateOrientation(_ o: AVCaptureVideoOrientation, on preview: AVCaptureVideoPreviewLayer) {
            // 预览层方向
            if let conn = preview.connection, conn.isVideoOrientationSupported {
                conn.videoOrientation = o
            }
            // 数据输出方向（如果存在）
            if let conn = videoOutput?.connection(with: .video),
               conn.isVideoOrientationSupported {
                conn.videoOrientation = o
            }
        }
    }
}

/// 带 AVCaptureVideoPreviewLayer 的视图
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = AVCaptureSession()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}