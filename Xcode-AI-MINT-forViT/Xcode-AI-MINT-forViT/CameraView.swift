import SwiftUI
import AVFoundation
import AppKit

struct CameraView: NSViewRepresentable {
    @Binding var isCapturing: Bool // 撮影開始/停止の状態
    var onCapture: (NSImage) -> Void // クロージャを追加
    var onCaptureComplete: (() -> Void)? // 撮影完了時の通知クロージャ

    class CameraPreviewView: NSView {
        var previewLayer: AVCaptureVideoPreviewLayer?
        let captureSession = AVCaptureSession()
        let photoOutput = AVCapturePhotoOutput()
        var timer: Timer?
        var photonum = 0
        var onCapture: ((NSImage) -> Void)? // クロージャを持たせる
        var isCapturing: Bool = false
        
        var onCaptureComplete: (() -> Void)?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupCamera()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupCamera()
        }

        private func setupCamera() {
            captureSession.sessionPreset = .high
            
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("カメラの入力を取得できません")
                return
            }
            
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.bounds
            self.layer = previewLayer
            self.previewLayer = previewLayer
            
            captureSession.startRunning()
        }

        // 1回だけ撮影を開始する
        func startCapturingPhotos() {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.photonum < 98 {
                    self.capturePhoto() // 画像をキャプチャ
                } else {
                    self.timer?.invalidate() // 98枚撮影したら停止
                }
            }
        }

        private func capturePhoto() {
                    let settings = AVCapturePhotoSettings()
                    photoOutput.capturePhoto(with: settings, delegate: self)
                    photonum += 1 // 撮影回数をカウント
                    print("Captured photo #\(photonum)")

                    if photonum >= 98 {
                        print("撮影を終了します。")
                        timer?.invalidate()
                        DispatchQueue.main.async {
                            self.isCapturing = false
                            self.photonum = 0
                            self.onCaptureComplete?() // ContentView に通知
                        }
                    }
                }


        override func layout() {
            super.layout()
            previewLayer?.frame = self.bounds
        }

        deinit {
            timer?.invalidate()
        }
    }

    func makeNSView(context: Context) -> CameraPreviewView {
            let previewView = CameraPreviewView()
            previewView.onCapture = onCapture
            previewView.onCaptureComplete = onCaptureComplete // クロージャを渡す
            return previewView
        }

        func updateNSView(_ nsView: CameraPreviewView, context: Context) {
            nsView.isCapturing = isCapturing
            if isCapturing {
                nsView.startCapturingPhotos()
            }
        }
}

extension NSImage {
    func cropped(to rect: CGRect) -> NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("CGImageの取得に失敗しました")
            return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            print("画像のクロップに失敗しました")
            return nil
        }

        return NSImage(cgImage: croppedCGImage, size: NSSize(width: rect.width, height: rect.height))
    }
}


extension CameraView.CameraPreviewView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("写真のキャプチャに失敗しました: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("写真データを取得できません")
            return
        }

        // NSImage に変換
        if let nsImage = NSImage(data: imageData) {
            DispatchQueue.main.async {
                self.onCapture?(nsImage) // クロージャを通じて画像を渡す
            }
        }
    }
}
