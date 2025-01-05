import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var images: [NSImage] = []
    @State private var predictionResult: String? = nil
    @State private var isCapturing: Bool = false // 初期値は `false` に設定して撮影をすぐに開始しない
    @State private var cameraPermissionGranted: Bool = false // カメラ許可の状態を管理

    private let modelHandler = AIModelHandler()
    private let imagePreprocessor = ImagePreprocessor()

    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                if cameraPermissionGranted {
                    CameraView(isCapturing: $isCapturing, onCapture: { capturedImage in
                        handleCapturedImage(capturedImage)
                    }, onCaptureComplete: {
                        print("撮影完了 - ContentView 側")
                    })
                    .frame(width: 640, height: 480)

                    // 赤枠の描画
                    Rectangle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 2)
                        .frame(width: 200, height: 200)

                    // スクロールするテキストを上に配置
                    VStack {
                        ScrollingTextView(text: predictionResult ?? "")
                            .frame(height: 50)
                            .padding(.top, 10)
                        Spacer()
                    }
                    .frame(width: 640, height: 480, alignment: .top)
                } else {
                    Text("カメラの許可を待っています...")
                        .font(.headline)
                        .padding()
                }
            }
            .padding()
        }
        .onAppear {
            checkCameraPermissionAndStart() // カメラ許可を確認して撮影を開始
        }
    }

    private func checkCameraPermissionAndStart() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            // カメラの許可がまだ確認されていない場合、許可をリクエスト
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if granted {
                        startCaptureSessionWithDelay()
                    } else {
                        print("カメラの許可が拒否されました")
                    }
                }
            }
        case .authorized:
            // カメラの許可がすでに与えられている場合
            cameraPermissionGranted = true
            startCaptureSessionWithDelay()
        case .denied, .restricted:
            // カメラの許可が拒否または制限されている場合
            cameraPermissionGranted = false
            print("カメラの許可が拒否または制限されています")
        @unknown default:
            fatalError("未知のカメラ許可状態")
        }
    }

    private func startCaptureSessionWithDelay() {
        // 数秒間待ってから撮影を開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // 3秒後に撮影を開始
            startCaptureSession()
        }
    }

    private func startCaptureSession() {
        images.removeAll()
        isCapturing = true
        print("撮影を開始します")
    }

    private func handleCapturedImage(_ capturedImage: NSImage) {
        let cropRect = CGRect(x: (640 - 200) / 2, y: (480 - 200) / 2, width: 200, height: 200)
        if let croppedImage = capturedImage.cropped(to: cropRect) {
            if images.count < 98 {
                images.append(croppedImage)
                print("Current cropped image count: \(images.count)")
            }
        } else {
            print("画像のクロップに失敗しました")
        }

        if images.count == 98 {
            isCapturing = false
            predictFromImages()
        }
    }

    private func predictFromImages() {
        print("画像をAIモデルに送信します...")

        guard let preprocessedMultiArray = imagePreprocessor.preprocessImages(images: images) else {
            print("画像の前処理に失敗しました")
            predictionResult = "画像の前処理に失敗しました"
            restartCaptureSession()
            return
        }

        if let result = modelHandler.predict(images: preprocessedMultiArray) {
            predictionResult = result
            print("予測結果: \(result)")
        } else {
            print("予測に失敗しました")
            predictionResult = "予測に失敗しました"
        }

        restartCaptureSession()
    }

    private func restartCaptureSession() {
        print("Next Session")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startCaptureSession()
        }
    }
}
