import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var images: [NSImage] = []
    @State private var predictionResult: String? = nil
    @State private var isCapturing: Bool = false // 初期値は `false` に設定して撮影をすぐに開始しない
    @State private var cameraPermissionGranted: Bool = false // カメラ許可の状態を管理
    @StateObject private var faceLandmarkDetector = FaceLandmarkDetector()
    @State private var isDebugMode: Bool = false // デバッグモードのオン・オフを管理
    private let saveDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

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
                    
                    if isDebugMode {
                        // ランドマークの描画
                        GeometryReader { geometry in
                            ForEach(faceLandmarkDetector.landmarks.map { CGPoint(x: $0.0, y: $0.1) }, id: \.self) { point in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 5, height: 5)
                                    .position(
                                        x: point.x * geometry.size.width,
                                        y: point.y * geometry.size.height
                                    )
                            }
                        }
                    }

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
        // デバッグスイッチ
        Toggle("Debug Mode", isOn: $isDebugMode)
            .padding()
            .onChange(of: isDebugMode) { newValue in
            handleDebugModeChange(newValue)
        }
        
        // 撮影 or 予測のステータス表示
        VStack {
            Spacer()
            HStack {
                Spacer()
                Circle()
                    .fill(captureIndicatorColor)
                    .frame(width: 20, height: 20)
                    .padding(10)
            }
        }
    }
    
    // 丸の色を状態に応じて変更
    var captureIndicatorColor: Color {
        return isCapturing ? .green : .red
    }
    
    // デバッグモード切り替え時の処理
        private func handleDebugModeChange(_ isDebug: Bool) {
            if isDebug {
                print("Debug Mode: ON")
            } else {
                print("Debug Mode: OFF")
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
        // 画像サイズを取得
        guard let cgImage = capturedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("CGImageへの変換に失敗しました")
            return
        }
        
        faceLandmarkDetector.detectLandmarks(from: cgImage)
        // クロップするサイズ (200x200)
        let cropWidth: CGFloat = 430
        let cropHeight: CGFloat = 430

        // 中央を基準にクロップ領域を設定
        let offsetX = (CGFloat(cgImage.width) - cropWidth) / 2
        let offsetY = (CGFloat(cgImage.height) - cropHeight) / 2

        let cropRect = CGRect(x: offsetX, y: offsetY, width: cropWidth, height: cropHeight)

        if let croppedImage = capturedImage.cropped(to: cropRect) {
            if images.count < 98 {
                images.append(croppedImage)
                print("Current cropped image count: \(images.count)")

                // 画像をドキュメントに保存
                saveImageToDisk(croppedImage, index: images.count)
            }
        } else {
            print("画像のクロップに失敗しました")
        }

        if images.count == 98 {
            isCapturing = false
            predictFromImages()
            images.removeAll()
        }
    }


    private func saveImageToDisk(_ image: NSImage, index: Int) {
            let fileURL = saveDirectory.appendingPathComponent("captured_image_\(index).png")
            guard let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                print("画像の保存に失敗しました: \(index)")
                return
            }

            do {
                try pngData.write(to: fileURL)
                print("画像を保存しました: \(fileURL.path)")
            } catch {
                print("画像の保存中にエラーが発生しました: \(error.localizedDescription)")
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

        modelHandler.predict(images: preprocessedMultiArray) { result in
            if let result = result {
                predictionResult = result
                print("予測結果: \(result)")
            } else {
                print("予測に失敗しました")
                predictionResult = "予測に失敗しました"
            }

            restartCaptureSession()
        }

    }

    private func restartCaptureSession() {
        print("Next Session")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startCaptureSession()
        }
    }
}
